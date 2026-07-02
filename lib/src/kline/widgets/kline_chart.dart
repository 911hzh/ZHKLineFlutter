import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';
import 'package:kline_flutter/src/kline/widgets/scale_gesture_handler.dart';

/// K 线图核心组件。
///
/// 该组件负责横向滚动、缩放、选中、可见区计算和绘制调度。
/// 具体的网格、蜡烛、指标、覆盖层和选中详情都交给 [delegate] 实现，
/// 因此业务方可以在不修改 core chart 的情况下替换任意绘制层。
class KLineChart<T> extends StatefulWidget {
  /// 创建一个 K 线核心图表。
  const KLineChart({
    super.key,
    required this.dataSource,
    required this.delegate,
    this.controller,
    this.theme = const KLineTheme(),
    this.layout = const KLineLayoutConfig(),
    this.behavior = const KLineBehaviorConfig(),
    this.loadingBuilder,
    this.emptyBuilder,
    this.isLoading = false,
  });

  /// 需要绘制的数据源。
  ///
  /// 图表本身不关心数据模型字段，字段读取和布局节点生成由 [delegate] 决定。
  final List<T> dataSource;

  /// 图表绘制和交互代理。
  ///
  /// delegate 负责高度计算、布局节点、固定网格、滚动内容、覆盖层和选中 UI。
  final KLineChartDelegate<T> delegate;

  /// 外部控制器。
  ///
  /// 如果不传入，组件会创建内部控制器；传入后外部可以读取或驱动缩放、
  /// 滚动、选中项、可见区和指标状态。
  final KLineController? controller;

  /// 图表主题配置。
  final KLineTheme theme;

  /// 图表布局配置。
  final KLineLayoutConfig layout;

  /// 图表交互行为配置。
  final KLineBehaviorConfig behavior;

  /// 自定义加载态 UI。
  final WidgetBuilder? loadingBuilder;

  /// 自定义空数据 UI。
  final WidgetBuilder? emptyBuilder;

  /// 是否展示加载态。
  final bool isLoading;

  @override
  State<KLineChart<T>> createState() => _KLineChartState<T>();
}

class _KLineChartState<T> extends State<KLineChart<T>> {
  static const _scrollRequestAnimationDuration = Duration(milliseconds: 250);

  /// 当外部没有传入 controller 时，由组件自己持有并释放。
  late final KLineController _ownedController;

  /// 当前实际使用的 controller。
  ///
  /// 可能来自外部 [KLineChart.controller]，也可能是内部 [_ownedController]。
  /// 外部 controller 变化时会在 [didUpdateWidget] 中重新绑定监听。
  late KLineController _controller;

  /// 横向滚动视图的真实滚动控制器。
  ///
  /// [_controller] 是 package 暴露给业务侧的状态入口；[_scrollController] 是
  /// Flutter ScrollView 的实际执行者。两者需要通过监听彼此保持同步。
  final ScrollController _scrollController = ScrollController();

  /// 缩放手势的状态和 offset 计算集中放在独立处理器里。
  final ScaleGestureHandler _scaleGestureHandler = ScaleGestureHandler();

  /// 最近一次完整图表上下文，用于滚动通知回调拿到最新布局信息。
  KLineChartContext<T>? _latestContext;

  /// 当前是否处于用户手指直接拖动产生的滚动。
  ///
  /// Flutter 的滚动通知也会来自惯性滚动、jumpTo、animateTo。业务分页只应该响应
  /// 用户主动拖动，所以这里单独记录 dragDetails 是否存在。
  bool _isUserScrollInProgress = false;

  /// 最近已经消费过的一次性滚动请求版本号。
  ///
  /// controller 的滚动请求是命令式的；用 revision 可以避免同一请求在多次 build
  /// 或 post-frame 回调中被重复执行。
  int _lastHandledScrollRequestRevision = 0;

  /// 当前是否正在把 controller 的 offset 同步到 ScrollView。
  ///
  /// 同步期间 ScrollView 仍会触发 listener；该标记用于避免把内部同步误判为用户滚动。
  bool _isSyncingScrollFromController = false;

  @override
  void initState() {
    super.initState();
    _ownedController = KLineController();
    _controller = widget.controller ?? _ownedController;
    _scrollController.addListener(_handleScroll);
    _controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant KLineChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextController = widget.controller ?? _ownedController;
    if (nextController != _controller) {
      // controller 是可替换依赖。切换时必须解绑旧监听，再监听新 controller。
      _controller.removeListener(_handleControllerChange);
      _controller = nextController;
      _controller.addListener(_handleControllerChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _ownedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      // 加载态直接交给外部 builder；此时不创建图表上下文，也不触发 delegate 绘制。
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 本组件只负责准备视口、可见区和滚动容器；具体高度和绘制内容由 delegate 决定。
        final viewportSize = _resolveViewportSize(context, constraints);
        final itemCount = widget.dataSource.length;
        if (itemCount == 0) {
          // 空数据没有可见区和布局节点，保持占位简单，避免 delegate 读取空节点出错。
          return widget.emptyBuilder?.call(context) ??
              const Center(child: Text('暂无数据'));
        }

        final scaleLayout = _scaleGestureHandler.resolveLayout(
          controller: _controller,
          layout: widget.layout,
          itemCount: itemCount,
          viewportWidth: viewportSize.width,
        );
        final visibleRange = KLineChartLayoutUtils.computeVisibleRange(
          itemCount: itemCount,
          itemExtent: scaleLayout.itemExtent,
          viewportWidth: viewportSize.width,
          scrollOffset: scaleLayout.scrollOffset,
        );
        // 第一次 context 只包含基础布局信息，交给 delegate 生成业务布局节点。
        // 这里不能由 core 直接计算蜡烛/指标坐标，否则自定义 delegate 会被绕开。
        final layoutNodesContext = _createContext(
          viewportSize: viewportSize,
          itemCount: itemCount,
          itemExtent: scaleLayout.itemExtent,
          contentWidth: scaleLayout.contentWidth,
          visibleRange: visibleRange,
          layoutNodes: const [],
        );
        final layoutNodes = widget.delegate.getLayoutNodes(
          layoutNodesContext,
          widget.dataSource,
        );
        // 第二次 context 带上 delegate 返回的节点，绘制、选中和 overlay 都复用同一份结果。
        final chartContext = _createContext(
          viewportSize: viewportSize,
          itemCount: itemCount,
          itemExtent: scaleLayout.itemExtent,
          contentWidth: scaleLayout.contentWidth,
          visibleRange: visibleRange,
          layoutNodes: layoutNodes,
        );
        _latestContext = chartContext;
        _scaleGestureHandler.syncScrollOffsetBounds(
          controller: _controller,
          scrollOffset: scaleLayout.scrollOffset,
          isMounted: () => mounted,
        );
        _syncVisibleRange(chartContext);
        // 滚动目标依赖本轮布局尺寸，必须在 context 更新后再处理。
        _consumeScrollRequest(chartContext);
        // 数据更新或尺寸变化可能让当前 offset 不再处于“最新”位置；这里按 controller 状态补齐。
        _syncFollowingLatest();

        // 高度、覆盖层和选中浮层都统一交给 delegate，core 不假设副图数量或 UI 结构。
        final chartHeight = widget.delegate.chartHeight(chartContext);
        final selectedNode = chartContext.selectedNode;
        final overlayView = widget.delegate.buildOverlayView(
          context,
          chartContext,
        );
        final selectionView =
            selectedNode == null
                ? null
                : widget.delegate.buildSelectionView(
                  context,
                  chartContext,
                  selectedNode,
                );

        return SizedBox(
          height: chartHeight,
          child: GestureDetector(
            onScaleStart:
                widget.behavior.enableScale
                    ? (details) => _scaleGestureHandler.handleStart(
                      controller: _controller,
                      details: details,
                    )
                    : null,
            onScaleUpdate:
                widget.behavior.enableScale
                    ? (details) => _scaleGestureHandler.handleUpdate(
                      controller: _controller,
                      layout: widget.layout,
                      context: chartContext,
                      details: details,
                    )
                    : null,
            onTapUp:
                widget.behavior.enableCrosshair
                    ? (details) => _selectNearest(
                      chartContext,
                      details.localPosition,
                      isMove: false,
                    )
                    : null,
            onLongPressStart:
                widget.behavior.enableCrosshair
                    ? (details) => _selectNearest(
                      chartContext,
                      details.localPosition,
                      isMove: false,
                    )
                    : null,
            onLongPressMoveUpdate:
                widget.behavior.enableCrosshair
                    ? (details) => _selectNearest(
                      chartContext,
                      details.localPosition,
                      isMove: true,
                    )
                    : null,
            onLongPressEnd: (_) => _endInteraction(chartContext),
            child: Stack(
              children: [
                // 固定层：绘制不随横向滚动移动的网格、坐标轴等内容。
                Positioned.fill(
                  child: IgnorePointer(
                    // 固定层不参与命中测试，避免遮挡滚动层和手势识别。
                    child: CustomPaint(
                      painter: _KLineChartFixedPainter<T>(
                        context: chartContext,
                        delegate: widget.delegate,
                      ),
                    ),
                  ),
                ),
                // 滚动层：绘制蜡烛、指标线等随内容宽度横向滚动的图层。
                NotificationListener<ScrollNotification>(
                  onNotification:
                      (notification) => _handleUserScrollNotification(
                        chartContext,
                        notification,
                      ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: SizedBox(
                      // 滚动层宽度使用 contentWidth；高度使用 delegate 的整体高度，
                      // 让主图、副图和自定义区域共享同一个内容坐标系。
                      width: scaleLayout.contentWidth,
                      height: chartHeight,
                      child: CustomPaint(
                        painter: _KLineChartContentPainter<T>(
                          context: chartContext,
                          delegate: widget.delegate,
                        ),
                      ),
                    ),
                  ),
                ),
                // 覆盖层和选中层由 delegate 生成，适合放置水印、按钮、详情面板等 Widget。
                if (overlayView != null) overlayView,
                if (selectionView != null) selectionView,
              ],
            ),
          ),
        );
      },
    );
  }

  Size _resolveViewportSize(BuildContext context, BoxConstraints constraints) {
    final mediaSize = MediaQuery.sizeOf(context);
    final width =
        constraints.maxWidth.isFinite ? constraints.maxWidth : mediaSize.width;
    // 高度必须统一走 delegate：默认副图、自定义 indicator 高度和完全自定义 delegate
    // 都只在 chartHeight 里有完整信息。父布局给了有限高度时，尊重父布局约束。
    final height =
        constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : widget.delegate.chartHeight(_createSizingContext(width));
    return Size(width, height);
  }

  // 无界高度场景下，真实 context 还没创建；先给 delegate 一个只用于算高度的空 context。
  // chartHeight 不应该依赖 layoutNodes，依赖业务状态时可从 controller/layout/theme 读取。
  KLineChartContext<T> _createSizingContext(double width) {
    final itemExtent = _scaleGestureHandler.resolveItemExtent(
      layout: widget.layout,
      scale: _controller.scale,
    );
    return _createContext(
      viewportSize: Size(width, 0),
      itemCount: 0,
      itemExtent: itemExtent,
      contentWidth: 0,
      visibleRange: const KLineVisibleRange(start: 0, end: -1),
      layoutNodes: const [],
    );
  }

  /// 创建传给 delegate 的统一上下文对象。
  ///
  /// core 只负责填充 controller、layout、theme、视口、内容宽度和可见区；
  /// 业务坐标、指标点位等更具体的信息由 delegate 通过 layoutNodes 扩展。
  KLineChartContext<T> _createContext({
    required Size viewportSize,
    required int itemCount,
    required double itemExtent,
    required double contentWidth,
    required KLineVisibleRange visibleRange,
    required List<KLineLayoutNode<T>> layoutNodes,
  }) {
    return KLineChartContext<T>(
      controller: _controller,
      layout: widget.layout,
      theme: widget.theme,
      viewportSize: viewportSize,
      itemCount: itemCount,
      itemExtent: itemExtent,
      contentWidth: contentWidth,
      visibleRange: visibleRange,
      layoutNodes: layoutNodes,
    );
  }

  /// 将当前可见区同步回 controller，供业务侧读取或联动其它 UI。
  ///
  /// 这个方法只暴露状态，不反向驱动滚动；真正的滚动命令走 scrollRequest。
  void _syncVisibleRange(KLineChartContext<T> context) {
    if (_controller.visibleRange == context.visibleRange) return;
    // build 阶段不能同步 notifyListeners；延后一帧把最新可见区暴露给外部 controller。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.setVisibleRange(context.visibleRange);
    });
  }

  /// ScrollView 的真实 offset 变化时，同步到公开 controller。
  ///
  /// 这个 listener 会收到用户拖动、惯性滚动、jumpTo/animateTo 等所有变化；
  /// 是否通知业务分页由 [_handleUserScrollNotification] 单独判断。
  void _handleScroll() {
    final position = _scrollController.position;
    final offset =
        _scrollController.offset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    _controller.setScrollOffset(offset);
    // 程序化滚动只是同步视口，不应该像用户拖动一样清掉十字线选中态。
    if (widget.behavior.clearSelectionOnScroll &&
        !_isSyncingScrollFromController) {
      _controller.clearSelection();
    }
  }

  /// 过滤横向滚动通知，并只把用户主动拖动交给 delegate。
  ///
  /// 返回 false 表示不拦截通知，让 Flutter 默认滚动行为继续执行。
  bool _handleUserScrollNotification(
    KLineChartContext<T> context,
    ScrollNotification notification,
  ) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _isUserScrollInProgress = notification.dragDetails != null;
      return false;
    }
    if (notification is ScrollEndNotification) {
      _isUserScrollInProgress = false;
      return false;
    }
    // 惯性滚动或程序化 jumpTo/animateTo 也会产生 ScrollUpdateNotification；
    // delegate.didScroll 只描述用户主动拖动，避免业务分页被内部同步误触发。
    if (notification is! ScrollUpdateNotification || !_isUserScrollInProgress) {
      return false;
    }
    // 用户手动离开当前位置后，不再强行跟随 socket 推来的最新 K 线。
    _controller.setFollowingLatest(false);

    // 只把用户主动拖动产生的滚动通知交给 delegate，避免外部 jumpTo 造成重复回调。
    widget.delegate.didScroll(
      _latestContext ?? context,
      KLineScrollMetrics(
        pixels: metrics.pixels,
        minScrollExtent: metrics.minScrollExtent,
        maxScrollExtent: metrics.maxScrollExtent,
        viewportDimension: metrics.viewportDimension,
        scrollDelta: notification.scrollDelta ?? 0,
        extentBefore: metrics.extentBefore,
        extentAfter: metrics.extentAfter,
      ),
    );
    return false;
  }

  // Controller 可能由缩放、跟随最新或外部调用主动改变 offset。
  // 这里把 controller 的目标位置同步到真实 ScrollView；普通拖动时两边
  // offset 通常已一致，会被下面的差值判断直接跳过。
  void _syncScrollPositionFromController() {
    if (_isSyncingScrollFromController) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target =
        _controller.scrollOffset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if ((position.pixels - target).abs() < 0.5) return;
    _isSyncingScrollFromController = true;
    try {
      _scrollController.jumpTo(target);
    } finally {
      _isSyncingScrollFromController = false;
    }
  }

  /// controller 状态变化入口。
  ///
  /// 外部可能调用 controller 设置缩放、滚动、选中项或指标状态；这里负责同步
  /// ScrollView 并触发重建，让下一帧重新计算 context 和绘制。
  void _handleControllerChange() {
    _syncScrollPositionFromController();
    if (mounted) setState(() {});
  }

  /// 消费 controller 中的一次性滚动请求。
  ///
  /// scrollToLatest、scrollToIndex、revealSelected 都会转成 scrollRequest。
  /// 执行必须等本帧布局完成，因为目标 offset 依赖 contentWidth、viewportSize 和 ScrollPosition 边界。
  void _consumeScrollRequest(KLineChartContext<T> context) {
    final request = _controller.scrollRequest;
    if (request == null ||
        request.revision == _lastHandledScrollRequestRevision) {
      return;
    }
    // 滚动目标依赖最新布局和 ScrollPosition 边界，所以等本帧完成后再执行。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) return;
      _lastHandledScrollRequestRevision = request.revision;
      if (request.latest) {
        await _scrollToOffset(0, animated: request.animated);
        _controller.consumeScrollRequest(request.revision);
        return;
      }
      final index = request.index;
      if (index == null) {
        _controller.consumeScrollRequest(request.revision);
        return;
      }
      // contentWidth 可能大于 itemCount * itemExtent，尾部对齐时要把这段
      // 额外宽度算进去，否则“滚到最旧”会差一点到不了右侧边界。
      final target =
          index * context.itemExtent -
          (context.viewportSize.width - context.itemExtent) *
              request.alignment.factor +
          (context.contentWidth - context.itemCount * context.itemExtent) *
              request.alignment.factor;
      // controller 只表达目标，最终仍按 ScrollView 当前真实可滚动范围裁剪。
      final maxScrollOffset = math.max(
        0.0,
        context.contentWidth - context.viewportSize.width,
      );
      await _scrollToOffset(
        target.clamp(0, maxScrollOffset).toDouble(),
        animated: request.animated,
      );
      _controller.consumeScrollRequest(request.revision);
    });
  }

  /// 把 ScrollView 滚到指定 offset。
  ///
  /// 这里集中处理 animateTo/jumpTo，并用 [_isSyncingScrollFromController] 标记内部同步，
  /// 防止同步过程中清除选中态或触发业务滚动回调。
  Future<void> _scrollToOffset(double target, {required bool animated}) async {
    _isSyncingScrollFromController = true;
    try {
      if (animated) {
        await _scrollController.animateTo(
          target,
          duration: _scrollRequestAnimationDuration,
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    } finally {
      _isSyncingScrollFromController = false;
      // 动画或 jumpTo 可能被边界裁剪，结束后以 ScrollView 的真实 offset 回写 controller。
      if (mounted && _scrollController.hasClients) {
        _controller.setScrollOffset(_scrollController.offset);
      }
    }
  }

  /// 当 controller 处于“跟随最新”状态时，把视口保持在最新一侧。
  ///
  /// 当前坐标系中 scrollOffset 为 0 表示最新数据侧；当数据或布局变化导致 offset 偏离，
  /// 下一帧会把 offset 拉回 0。
  void _syncFollowingLatest() {
    if (!_controller.isFollowingLatest || _controller.scrollOffset == 0) {
      return;
    }
    // 数据或尺寸变化后，只要仍处于跟随最新，就保持最新一根可见。
    // 这里不判断插入方向，插入位置由业务层决定。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _controller.setScrollOffset(0);
    });
  }

  /// 根据手势位置选择最近的布局节点。
  ///
  /// 手势坐标是组件局部坐标，需要加上 scrollOffset 转成滚动内容坐标，
  /// 再和 delegate 生成的节点中心点比较。
  void _selectNearest(
    KLineChartContext<T> context,
    Offset localPosition, {
    required bool isMove,
  }) {
    if (context.layoutNodes.isEmpty) return;
    final x = localPosition.dx + _controller.scrollOffset;
    KLineLayoutNode<T>? nearest;
    var nearestDistance = double.infinity;
    // 根据手势横坐标查找最近的布局节点，保证十字线吸附到对应 K 线中心。
    for (final node in context.layoutNodes) {
      final distance = (node.centerX - x).abs();
      if (distance < nearestDistance) {
        nearest = node;
        nearestDistance = distance;
      }
    }
    if (nearest == null) return;
    _controller.selectIndex(
      nearest.index,
      localPosition: localPosition,
      contentPosition: Offset(x, localPosition.dy),
    );
    if (isMove) {
      widget.delegate.didMoveSelection(context, nearest);
    } else {
      widget.delegate.didSelectItem(context, nearest);
    }
  }

  /// 结束长按/缩放交互时处理选中态。
  ///
  /// 是否保留十字线由 behavior 决定，core 不在这里强制隐藏。
  void _endInteraction(KLineChartContext<T> context) {
    if (!widget.behavior.keepCrosshairOnLongPressEnd) {
      _controller.clearSelection();
    }
  }
}

class _KLineChartFixedPainter<T> extends CustomPainter {
  const _KLineChartFixedPainter({
    required this.context,
    required this.delegate,
  });

  final KLineChartContext<T> context;
  final KLineChartDelegate<T> delegate;

  @override
  void paint(Canvas canvas, Size size) {
    // 固定层只负责视口坐标系内容，例如网格线、固定价格轴或十字线。
    delegate.drawGrid(canvas, size, context);
  }

  @override
  bool shouldRepaint(covariant _KLineChartFixedPainter<T> oldDelegate) {
    return oldDelegate.context != context || oldDelegate.delegate != delegate;
  }
}

class _KLineChartContentPainter<T> extends CustomPainter {
  const _KLineChartContentPainter({
    required this.context,
    required this.delegate,
  });

  final KLineChartContext<T> context;
  final KLineChartDelegate<T> delegate;

  @override
  void paint(Canvas canvas, Size size) {
    // 内容层使用滚动内容坐标系，蜡烛、指标线和副图都会随 ScrollView 横向移动。
    delegate.drawChart(canvas, size, context);
  }

  @override
  bool shouldRepaint(covariant _KLineChartContentPainter<T> oldDelegate) {
    return oldDelegate.context != context || oldDelegate.delegate != delegate;
  }
}
