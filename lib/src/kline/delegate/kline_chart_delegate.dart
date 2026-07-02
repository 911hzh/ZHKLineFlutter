import 'package:flutter/material.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';

/// 绘制布局节点。
///
/// core 负责计算 [frame] 这类通用布局信息；业务 delegate 可以在
/// [KLineChartDelegate.getLayoutNodes] 中返回子类，缓存开高低收、指标点位等
/// 已经计算好的坐标，避免每次绘制重复计算。
@immutable
class KLineLayoutNode<T> {
  const KLineLayoutNode({
    required this.index,
    required this.item,
    required this.frame,
  });

  /// 数据在 dataSource 中的原始下标。
  final int index;

  /// dataSource 返回的业务数据对象。
  final T item;

  /// 当前节点在横向滚动内容坐标系中的基础区域。
  final Rect frame;

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

  /// 根据可见范围从 dataSource 取数据，并构建默认布局节点列表。
  static List<KLineLayoutNode<T>> buildLayoutNodes<T>({
    required KLineChartContext<T> context,
    required List<T> dataSource,
    required KLineVisibleRange visibleRange,
  }) {
    final nodes = <KLineLayoutNode<T>>[];
    for (var index = visibleRange.start; index <= visibleRange.end; index++) {
      final left = index * context.itemExtent;
      nodes.add(
        KLineLayoutNode<T>(
          index: index,
          item: dataSource[index],
          frame: Rect.fromLTWH(
            left,
            0,
            context.itemExtent,
            context.viewportSize.height,
          ),
        ),
      );
    }
    return nodes;
  }
}

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
/// package 会在布局、绘制、交互回调中把该对象传给 delegate。
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

  /// dataSource 数组中的数据总数。
  final int itemCount;

  /// 单个 item 的横向占位宽度。
  final double itemExtent;

  /// 横向滚动内容总宽度。
  final double contentWidth;

  /// 当前可见下标范围。
  final KLineVisibleRange visibleRange;

  /// 当前绘制布局节点。
  final List<KLineLayoutNode<T>> layoutNodes;

  /// 当前选中的布局节点；如果选中项不在可见范围内则返回 null。
  KLineLayoutNode<T>? get selectedNode {
    final selectedIndex = controller.selectedIndex;
    if (selectedIndex == null) return null;
    for (final node in layoutNodes) {
      if (node.index == selectedIndex) return node;
    }
    return null;
  }
}

/// 图表代理，负责尺寸、布局节点、绘制、选中 UI 和交互回调。
///
/// package core 不直接绘制业务内容。外部可以通过覆盖这些方法，自定义网格、
/// 蜡烛、指标、副图、覆盖层、详情浮层以及可见项/布局节点计算。
abstract class KLineChartDelegate<T> {
  const KLineChartDelegate();

  /// 图表整体高度，默认只包含主图高度。
  ///
  /// 业务方可以在这里把副图、指标切换栏或自定义底部区域的高度一起追加进去。
  double chartHeight(KLineChartContext<T> context) {
    return context.layout.mainChartHeight;
  }

  /// 返回当前绘制布局节点。
  ///
  /// core 已经在 [context.visibleRange] 中计算好可见范围。默认实现会按该范围
  /// 从 [dataSource] 读取可见 item，再生成默认布局节点。业务 delegate 可以覆盖
  /// 该方法，在一个入口里自行计算可见节点并返回带有业务坐标的 node 子类。
  List<KLineLayoutNode<T>> getLayoutNodes(
    KLineChartContext<T> context,
    List<T> dataSource,
  ) {
    return KLineChartLayoutUtils.buildLayoutNodes(
      context: context,
      dataSource: dataSource,
      visibleRange: context.visibleRange,
    );
  }

  /// 绘制滚动内容层。
  ///
  /// 默认依次调用 [drawMainChart] 和 [drawSecondaryCharts]。如果业务方希望自行
  /// 批量组织所有滚动内容绘制，可以直接覆盖该方法。
  void drawChart(Canvas canvas, Size size, KLineChartContext<T> context) {
    drawMainChart(canvas, size, context);
    drawSecondaryCharts(canvas, size, context);
  }

  /// 绘制固定网格层。该层不随横向内容滚动。
  ///
  /// 固定在视口上的十字线、价格轴辅助线等，也可以放在该层绘制。
  void drawGrid(Canvas canvas, Size size, KLineChartContext<T> context) {}

  /// 绘制主图滚动内容，例如蜡烛、分时线、MA/BOLL 等主图指标。
  void drawMainChart(Canvas canvas, Size size, KLineChartContext<T> context) {}

  /// 绘制副图滚动内容，例如 VOL、MACD、KDJ、RSI、WR 等。
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
  ) {}

  /// 构建选中项详情 UI。
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<T> chartContext,
    KLineLayoutNode<T> selectedNode,
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

  /// 用户拖动导致横向滚动位置变化时回调。
  ///
  /// 手指拖动和松手后的惯性滚动都会触发；首次数据加载、外部 controller 设置
  /// offset、内部同步 scrollPosition 等程序化滚动不会触发该回调。
  /// 业务方可以在这里根据左右边界和阈值决定加载旧数据或最新数据。
  void didScroll(KLineChartContext<T> context, KLineScrollMetrics metrics) {}

  /// 选中某个节点时回调。
  void didSelectItem(KLineChartContext<T> context, KLineLayoutNode<T> node) {}

  /// 长按移动选中节点时回调。
  void didMoveSelection(
    KLineChartContext<T> context,
    KLineLayoutNode<T> node,
  ) {}
}
