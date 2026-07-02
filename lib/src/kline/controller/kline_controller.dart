import 'dart:ui';

import 'package:flutter/foundation.dart';

/// 滚动到指定 K 线时，目标 K 线在视口中的对齐位置。
enum KLineScrollAlignment {
  /// 靠左显示。
  left(0),

  /// 居中显示。
  center(0.5),

  /// 靠右显示。
  right(1);

  const KLineScrollAlignment(this.factor);

  /// 视口内的对齐比例，0 为左侧，1 为右侧。
  final double factor;
}

/// 当前图表可见数据区间。
///
/// [start] 和 [end] 都是数据源中的下标，用于让外部知道当前屏幕正在展示
/// 哪一段 K 线数据。业务方可以据此触发加载更多、同步外部列表或更新顶部信息。
@immutable
class KLineVisibleRange {
  /// 创建一个可见区间。
  const KLineVisibleRange({required this.start, required this.end});

  /// 可见区间起始下标。
  final int start;

  /// 可见区间结束下标。
  final int end;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KLineVisibleRange &&
            runtimeType == other.runtimeType &&
            start == other.start &&
            end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'KLineVisibleRange(start: $start, end: $end)';
}

/// K 线图公开控制器。
///
/// 该控制器集中保存缩放、滚动、选中项、可见区间和当前启用指标等状态。
/// 外部页面可以读取这些状态，也可以主动调用方法驱动图表交互。
class KLineController extends ChangeNotifier {
  /// 创建 K 线图控制器。
  ///
  /// [initialScale] 是初始缩放比例，[initialScrollOffset] 是初始滚动偏移，
  /// [initialIndicators] 是默认启用的副图或指标 id。
  ///
  /// [initialFollowLatest] 只表示“数据或尺寸变化后继续看最新”，不负责判断
  /// 新数据应该插入到哪个位置；插入位置仍由业务数据层决定。
  KLineController({
    double initialScale = 1,
    double initialScrollOffset = 0,
    Iterable<String> initialIndicators = const [],
    bool initialFollowLatest = false,
  }) : _scale = initialScale,
       _scrollOffset = initialScrollOffset,
       _activeIndicatorIds = List<String>.unmodifiable(initialIndicators),
       _isFollowingLatest = initialFollowLatest;

  double _scale;
  double _scrollOffset;
  int? _selectedIndex;
  Offset? _selectionLocalPosition;
  Offset? _selectionContentPosition;
  KLineVisibleRange? _visibleRange;
  List<String> _activeIndicatorIds;
  bool _isFollowingLatest;

  // 滚动请求是一次性命令：业务先更新数据，再调用滚动方法；图表完成布局
  // 后消费并清空，避免 controller 变成数据插入策略的状态机。
  int _scrollRequestRevision = 0;
  bool _shouldScrollToLatest = false;
  int? _scrollToIndex;
  KLineScrollAlignment _scrollAlignment = KLineScrollAlignment.right;
  bool _scrollAnimated = true;

  /// 当前缩放比例。
  double get scale => _scale;

  /// 当前横向滚动偏移。
  double get scrollOffset => _scrollOffset;

  /// 当前选中的数据下标，未选中时为 null。
  int? get selectedIndex => _selectedIndex;

  /// 当前选中点在图表组件局部坐标系中的位置。
  Offset? get selectionLocalPosition => _selectionLocalPosition;

  /// 当前选中点在滚动内容坐标系中的位置。
  Offset? get selectionContentPosition => _selectionContentPosition;

  /// 当前屏幕可见的数据区间。
  KLineVisibleRange? get visibleRange => _visibleRange;

  /// 当前启用的指标 id 列表。
  List<String> get activeIndicatorIds => _activeIndicatorIds;

  /// 当前是否跟随最新数据。
  ///
  /// 开启后，图表会在数据或尺寸变化时保持最新一根 K 线可见。
  bool get isFollowingLatest => _isFollowingLatest;

  /// 当前待处理的一次性滚动请求。
  ///
  /// 该入口供图表内部消费；业务侧通常只需要调用 [scrollToLatest]、
  /// [scrollToIndex] 或 [revealSelected]。每次请求通过 [revision] 区分，
  /// 这样连续请求不会被旧的 post-frame 回调误消费。
  ({
    int revision,
    bool latest,
    int? index,
    KLineScrollAlignment alignment,
    bool animated,
  })?
  get scrollRequest {
    if (_scrollRequestRevision == 0) return null;
    return (
      revision: _scrollRequestRevision,
      latest: _shouldScrollToLatest,
      index: _scrollToIndex,
      alignment: _scrollAlignment,
      animated: _scrollAnimated,
    );
  }

  /// 消费完一次滚动请求后清空请求。
  ///
  /// 只清空目标，不重置 revision，方便图表识别“上一条请求已经处理过”。
  void consumeScrollRequest(int revision) {
    if (_scrollRequestRevision != revision) return;
    _shouldScrollToLatest = false;
    _scrollToIndex = null;
  }

  /// 设置缩放比例。
  ///
  /// 该方法只更新缩放值，不会自动围绕某个手势焦点修正滚动偏移。
  void setScale(double value) {
    if (_scale == value) return;
    _scale = value;
    notifyListeners();
  }

  /// 围绕手势焦点设置缩放比例。
  ///
  /// 缩放时会根据 [baseScale]、[localFocalX] 和 [contentFocalX]
  /// 同步计算新的滚动偏移，让用户手指下方的内容尽量保持稳定。
  void setScaleAroundFocalPoint({
    required double scale,
    required double baseScale,
    required double localFocalX,
    required double contentFocalX,
    double? minScrollOffset,
    double? maxScrollOffset,
  }) {
    if (baseScale == 0) return;
    final scaleRatio = scale / baseScale;
    var nextScrollOffset = contentFocalX * scaleRatio - localFocalX;
    if (minScrollOffset != null || maxScrollOffset != null) {
      nextScrollOffset =
          nextScrollOffset
              .clamp(
                minScrollOffset ?? double.negativeInfinity,
                maxScrollOffset ?? double.infinity,
              )
              .toDouble();
    }
    final scaleChanged = _scale != scale;
    final scrollChanged = _scrollOffset != nextScrollOffset;
    if (!scaleChanged && !scrollChanged) return;
    _scale = scale;
    _scrollOffset = nextScrollOffset;
    notifyListeners();
  }

  /// 设置横向滚动偏移。
  void setScrollOffset(double value) {
    if (_scrollOffset == value) return;
    _scrollOffset = value;
    notifyListeners();
  }

  /// 设置是否跟随最新数据。
  ///
  /// 这里只切换模式，不立刻发起滚动；业务需要马上回到最新时可调用
  /// [scrollToLatest]。
  void setFollowingLatest(bool value) {
    if (_isFollowingLatest == value) return;
    _isFollowingLatest = value;
    notifyListeners();
  }

  /// 触发“滚动到最新”命令。
  ///
  /// 主动回到最新后默认重新进入跟随最新模式。
  void scrollToLatest({bool animated = true}) {
    _isFollowingLatest = true;
    _shouldScrollToLatest = true;
    _scrollToIndex = null;
    _scrollAnimated = animated;
    _scrollRequestRevision++;
    notifyListeners();
  }

  /// 触发“滚动到指定下标”命令。
  ///
  /// 主动查看指定位置通常表示用户暂时离开最新区域，因此会关闭跟随最新。
  void scrollToIndex(
    int index, {
    KLineScrollAlignment alignment = KLineScrollAlignment.right,
    bool animated = true,
  }) {
    _isFollowingLatest = false;
    _shouldScrollToLatest = false;
    _scrollToIndex = index;
    _scrollAlignment = alignment;
    _scrollAnimated = animated;
    _scrollRequestRevision++;
    notifyListeners();
  }

  /// 当存在选中项时，将其滚回可见区域。
  ///
  /// 复用 [scrollToIndex]，所以 reveal 选中项也会关闭跟随最新。
  void revealSelected({
    KLineScrollAlignment alignment = KLineScrollAlignment.center,
    bool animated = true,
  }) {
    final selectedIndex = _selectedIndex;
    if (selectedIndex == null) return;
    scrollToIndex(selectedIndex, alignment: alignment, animated: animated);
  }

  /// 选中或清除某一根 K 线。
  ///
  /// [index] 为 null 时表示清除选中态。选中时可以同时传入局部坐标
  /// [localPosition] 和内容坐标 [contentPosition]，供十字线与详情面板定位。
  void selectIndex(
    int? index, {
    Offset? localPosition,
    Offset? contentPosition,
  }) {
    final nextLocalPosition = index == null ? null : localPosition;
    final nextContentPosition = index == null ? null : contentPosition;
    if (_selectedIndex == index &&
        _selectionLocalPosition == nextLocalPosition &&
        _selectionContentPosition == nextContentPosition) {
      return;
    }
    _selectedIndex = index;
    _selectionLocalPosition = nextLocalPosition;
    _selectionContentPosition = nextContentPosition;
    notifyListeners();
  }

  /// 清除当前选中态。
  void clearSelection() => selectIndex(null);

  /// 更新当前屏幕可见数据区间。
  void setVisibleRange(KLineVisibleRange? range) {
    if (_visibleRange == range) return;
    _visibleRange = range;
    notifyListeners();
  }

  /// 替换当前启用的指标 id 列表。
  void setActiveIndicators(Iterable<String> indicatorIds) {
    final next = List<String>.unmodifiable(indicatorIds);
    if (listEquals(_activeIndicatorIds, next)) return;
    _activeIndicatorIds = next;
    notifyListeners();
  }

  /// 切换某个指标 id 的启用状态。
  void toggleIndicator(String indicatorId) {
    final next = [..._activeIndicatorIds];
    if (next.contains(indicatorId)) {
      next.remove(indicatorId);
    } else {
      next.add(indicatorId);
    }
    setActiveIndicators(next);
  }
}
