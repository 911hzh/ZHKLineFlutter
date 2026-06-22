import 'package:flutter/material.dart';

import '../controller/kline_controller.dart';
import '../theme/kline_theme.dart';

/// 当前可见范围内的单个数据项。
///
/// core 负责计算 [frame] 这类通用布局信息，业务方可在 delegate 中继续
/// 基于它计算蜡烛、指标、覆盖层等更具体的绘制坐标。
@immutable
class KLineVisibleItem<T> {
  const KLineVisibleItem({
    required this.index,
    required this.item,
    required this.frame,
  });

  /// 数据在 dataSource 中的原始下标。
  final int index;

  /// dataSource 返回的业务数据对象。
  final T item;

  /// 当前 item 在横向滚动内容坐标系中的基础区域。
  final Rect frame;

  /// 基础区域中心点。
  Offset get center => frame.center;

  /// 基础区域中心 x 坐标，通常作为蜡烛中心点。
  double get centerX => frame.center.dx;
}

/// 绘制布局节点。
///
/// [KLineVisibleItem] 只表示可见 item 的基础 frame；业务 delegate 可以在
/// [KLineChartDelegate.getLayoutNodes] 中返回子类，缓存开高低收、指标点位等
/// 已经计算好的坐标，避免每次绘制重复计算。
@immutable
class KLineLayoutNode<T> {
  const KLineLayoutNode({required this.visibleItem, required this.frame});

  /// 节点对应的可见数据项。
  final KLineVisibleItem<T> visibleItem;

  /// 节点用于绘制的区域，默认等于 visibleItem.frame。
  final Rect frame;

  /// 便捷访问原始下标。
  int get index => visibleItem.index;

  /// 便捷访问业务数据。
  T get item => visibleItem.item;

  /// 节点中心点。
  Offset get center => frame.center;

  /// 节点中心 x 坐标。
  double get centerX => center.dx;
}

/// K 线图表默认布局工具。
///
/// 这些方法是 delegate 默认实现使用的工具方法；业务方可以直接复用，也可以在
/// delegate 中覆盖对应方法实现完全自定义的可见项/布局节点计算。
abstract final class KLineChartLayoutUtils {
  /// 根据总数量、item 宽度、视口宽度和滚动偏移计算当前可见下标范围。
  static KLineVisibleRange computeVisibleRange({
    required int itemCount,
    required double itemExtent,
    required double viewportWidth,
    required double scrollOffset,
  }) {
    final start = (scrollOffset / itemExtent).floor().clamp(0, itemCount - 1);
    final visibleCount = (viewportWidth / itemExtent).ceil() + 1;
    final end = (start + visibleCount).clamp(start, itemCount - 1);
    return KLineVisibleRange(start: start, end: end);
  }

  /// 根据可见范围从 dataSource 取数据，并构建默认可见 item 列表。
  static List<KLineVisibleItem<T>> buildVisibleItems<T>({
    required KLineChartContext<T> context,
    required KLineChartDataSource<T> dataSource,
    required KLineVisibleRange visibleRange,
  }) {
    final items = <KLineVisibleItem<T>>[];
    for (var index = visibleRange.start; index <= visibleRange.end; index++) {
      final left = index * context.itemExtent;
      items.add(
        KLineVisibleItem<T>(
          index: index,
          item: dataSource.itemAt(context, index),
          frame: Rect.fromLTWH(
            left,
            0,
            context.itemExtent,
            context.viewportSize.height,
          ),
        ),
      );
    }
    return items;
  }

  /// 使用 visibleItems 构建默认布局节点。
  static List<KLineLayoutNode<T>> buildLayoutNodes<T>(
    List<KLineVisibleItem<T>> visibleItems,
  ) {
    return visibleItems
        .map((item) => KLineLayoutNode<T>(visibleItem: item, frame: item.frame))
        .toList();
  }
}

/// dataSource 请求数据时携带的上下文。
@immutable
class KLineDataRequest {
  const KLineDataRequest({required this.visibleRange, required this.reason});

  /// 触发请求时的可见范围。
  final KLineVisibleRange visibleRange;

  /// 本次请求由初始化、滚动、缩放还是 reload 触发。
  final KLineDataRequestReason reason;
}

/// 数据请求原因。
enum KLineDataRequestReason { initial, scroll, scale, reload }

/// 用户滚动时传给 delegate 的滚动位置信息。
///
/// core 只负责把 ScrollView 的当前位置和边界透出；业务方可根据 [pixels]、
/// [minScrollExtent]、[maxScrollExtent] 自行判断左侧或右侧阈值，例如距离右侧
/// 20px 时加载最新数据，或接近左侧时加载更旧数据。
@immutable
class KLineScrollMetrics {
  const KLineScrollMetrics({
    required this.pixels,
    required this.minScrollExtent,
    required this.maxScrollExtent,
    required this.viewportDimension,
    required this.scrollDelta,
    required this.extentBefore,
    required this.extentAfter,
  });

  /// 当前横向滚动偏移量。
  final double pixels;

  /// 最小可滚动位置，通常为 0。
  final double minScrollExtent;

  /// 最大可滚动位置，也就是内容最右侧。
  final double maxScrollExtent;

  /// 当前视口宽度。
  final double viewportDimension;

  /// 本次滚动更新相对上一帧的偏移变化。
  final double scrollDelta;

  /// 当前位置左侧已经滚过的距离。
  final double extentBefore;

  /// 当前位置右侧还剩余的距离。
  final double extentAfter;
}

/// 图表上下文。
///
/// package 会在布局、绘制、交互回调中把该对象传给 dataSource/delegate。
/// 业务方应优先通过这里读取当前 controller、主题、布局、可见项和布局节点。
class KLineChartContext<T> {
  const KLineChartContext({
    required this.controller,
    required this.layout,
    required this.theme,
    required this.viewportSize,
    required this.itemCount,
    required this.itemExtent,
    required this.contentWidth,
    required this.visibleRange,
    required this.visibleItems,
    required this.layoutNodes,
  });

  /// 当前图表控制器。
  final KLineController controller;

  /// 当前布局配置。
  final KLineLayoutConfig layout;

  /// 当前主题配置。
  final KLineTheme theme;

  /// 当前图表视口尺寸。
  final Size viewportSize;

  /// dataSource 中的数据总数。
  final int itemCount;

  /// 单个 item 的横向占位宽度。
  final double itemExtent;

  /// 横向滚动内容总宽度。
  final double contentWidth;

  /// 当前可见下标范围。
  final KLineVisibleRange visibleRange;

  /// 当前可见数据项。
  final List<KLineVisibleItem<T>> visibleItems;

  /// 当前绘制布局节点。
  final List<KLineLayoutNode<T>> layoutNodes;

  /// 当前选中的可见 item；如果选中项不在可见范围内则返回 null。
  KLineVisibleItem<T>? get selectedItem {
    final selectedIndex = controller.selectedIndex;
    if (selectedIndex == null) return null;
    for (final item in visibleItems) {
      if (item.index == selectedIndex) return item;
    }
    return null;
  }

  /// 当前选中的布局节点；如果选中项不在可见范围内则返回 null。
  KLineLayoutNode<T>? get selectedLayoutNode {
    final selectedIndex = controller.selectedIndex;
    if (selectedIndex == null) return null;
    for (final node in layoutNodes) {
      if (node.index == selectedIndex) return node;
    }
    return null;
  }
}

/// 图表数据源，职责类似 UITableViewDataSource。
///
/// package 只通过这个接口按需读取数据，不关心业务数据类型。
abstract class KLineChartDataSource<T> {
  const KLineChartDataSource();

  /// 返回当前数据总数。
  int numberOfItems(KLineChartContext<T> context);

  /// 返回指定下标的数据对象。
  T itemAt(KLineChartContext<T> context, int index);

  /// 当可见范围变化时通知外部按需加载或预加载数据。
  void chartDidRequestData(
    KLineChartContext<T> context,
    KLineDataRequest request,
  ) {}
}

/// 图表代理，负责尺寸、布局节点、绘制、选中 UI 和交互回调。
///
/// package core 不直接绘制业务内容。外部可以通过覆盖这些方法，自定义网格、
/// 蜡烛、指标、副图、覆盖层、详情浮层以及可见项/布局节点计算。
abstract class KLineChartDelegate<T> {
  const KLineChartDelegate();

  /// 单个 item 的横向占位宽度，默认等于蜡烛宽度 + 间距并跟随 scale。
  double itemExtent(KLineChartContext<T> context) {
    return context.layout.candleWidth * context.controller.scale +
        context.layout.candleSpacing * context.controller.scale;
  }

  /// 图表整体高度，默认只包含主图高度。
  double chartHeight(KLineChartContext<T> context) {
    return context.layout.mainChartHeight;
  }

  /// 返回当前可见范围。默认使用 [KLineChartLayoutUtils.computeVisibleRange]。
  KLineVisibleRange getVisibleRange(KLineChartContext<T> context) {
    return KLineChartLayoutUtils.computeVisibleRange(
      itemCount: context.itemCount,
      itemExtent: context.itemExtent,
      viewportWidth: context.viewportSize.width,
      scrollOffset: context.controller.scrollOffset,
    );
  }

  /// 返回当前可见 item 列表。默认从 dataSource 按 visibleRange 构建。
  List<KLineVisibleItem<T>> getVisibleItems(
    KLineChartContext<T> context,
    KLineChartDataSource<T> dataSource,
    KLineVisibleRange visibleRange,
  ) {
    return KLineChartLayoutUtils.buildVisibleItems(
      context: context,
      dataSource: dataSource,
      visibleRange: visibleRange,
    );
  }

  /// 返回当前绘制布局节点。可在这里预计算蜡烛坐标或指标坐标。
  List<KLineLayoutNode<T>> getLayoutNodes(KLineChartContext<T> context) {
    return KLineChartLayoutUtils.buildLayoutNodes(context.visibleItems);
  }

  /// 绘制固定网格层。该层不随横向内容滚动。
  void drawGrid(Canvas canvas, Size size, KLineChartContext<T> context) {}

  /// 批量绘制当前帧的布局节点。
  ///
  /// 默认逐个回调 [drawLayoutNode]，保证旧实现兼容。追求性能的业务方可以
  /// 覆盖该方法，基于 [nodes] 聚合 Path、drawPoints 或其它批量绘制命令。
  void drawLayoutNodes(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
    List<KLineLayoutNode<T>> nodes,
  ) {
    for (final node in nodes) {
      drawLayoutNode(canvas, size, context, node);
    }
  }

  /// 绘制单个布局节点。默认回退到旧的 [drawItem]，保持兼容。
  void drawLayoutNode(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
    KLineLayoutNode<T> node,
  ) {
    drawItem(canvas, size, context, node.visibleItem);
  }

  /// 绘制单个可见 item。旧 delegate 可以继续只实现该方法。
  void drawItem(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
    KLineVisibleItem<T> item,
  ) {}

  /// 绘制固定覆盖层，例如十字线。
  void drawOverlay(Canvas canvas, Size size, KLineChartContext<T> context) {}

  /// 构建选中项详情 UI。
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<T> chartContext,
    KLineVisibleItem<T> selectedItem,
  ) {
    return null;
  }

  /// 构建固定覆盖 UI，例如指标标签、底部指标切换栏。
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<T> chartContext,
  ) {
    return null;
  }

  /// 可见范围变化回调。
  void didUpdateVisibleRange(
    KLineChartContext<T> context,
    KLineVisibleRange visibleRange,
  ) {}

  /// 用户拖动导致横向滚动位置变化时回调。
  ///
  /// 首次数据加载、外部 controller 设置 offset、内部同步 scrollPosition 等程序化
  /// 滚动不会触发该回调。业务方可以在这里根据左右边界和阈值决定加载旧数据或最新数据。
  void didScroll(KLineChartContext<T> context, KLineScrollMetrics metrics) {}

  /// 选中某个 item 时回调。
  void didSelectItem(KLineChartContext<T> context, KLineVisibleItem<T> item) {}

  /// 长按移动选中项时回调。
  void didMoveSelection(
    KLineChartContext<T> context,
    KLineVisibleItem<T> item,
  ) {}

  /// 缩放开始回调。
  void didStartScale(KLineChartContext<T> context, double scale) {}

  /// 缩放更新回调。
  void didUpdateScale(KLineChartContext<T> context, double scale) {}

  /// 缩放结束回调。
  void didEndScale(KLineChartContext<T> context, double scale) {}

  /// 点击、长按或手势交互结束回调。
  void didEndInteraction(KLineChartContext<T> context) {}
}
