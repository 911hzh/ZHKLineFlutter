// ignore_for_file: file_names

// K 线 Demo 绘制代理：复刻旧 Demo 的网格、蜡烛、指标和交互覆盖层绘制。
part of 'KLineDemoPage.dart';

/// Demo 专用 layout node，保存蜡烛绘制需要的坐标和样式。
class _KLineDemoLayoutNode extends KLineLayoutNode<KLineModel> {
  const _KLineDemoLayoutNode({
    required super.index,
    required super.item,
    required super.frame,
    required this.centerX,
    required this.bodyWidth,
    required this.highY,
    required this.lowY,
    required this.openY,
    required this.closeY,
    required this.candleColor,
  });

  @override
  final double centerX;
  final double bodyWidth;
  final double highY;
  final double lowY;
  final double openY;
  final double closeY;
  final Color candleColor;
}

/// K 线图表 delegate，集中承接 package 暴露出来的绘制与交互扩展点。
class _KLineDemoDelegate extends KLineChartDelegate<KLineModel> {
  const _KLineDemoDelegate({this.onScroll});

  final void Function(
    KLineChartContext<KLineModel> context,
    KLineScrollMetrics metrics,
  )?
  onScroll;

  /// 依据当前启用的副图数量计算完整图表高度。
  @override
  double chartHeight(KLineChartContext<KLineModel> context) {
    return KLineDemoDelegateDefaultImplUtil.chartHeight(context);
  }

  /// 仅在用户拖动滚动时由 core 回调，页面可在这里决定左侧或右侧加载。
  @override
  void didScroll(
    KLineChartContext<KLineModel> context,
    KLineScrollMetrics metrics,
  ) {
    onScroll?.call(context, metrics);
  }

  /// 根据当前可见数据预计算蜡烛坐标，绘制阶段直接消费 layout node。
  @override
  List<KLineLayoutNode<KLineModel>> getLayoutNodes(
    KLineChartContext<KLineModel> context,
    List<KLineModel> dataSource,
  ) {
    return KLineDemoDelegateDefaultImplUtil.getLayoutNodes(context, dataSource);
  }

  /// 绘制固定网格层，包括主图边界、价格轴、日期轴和副图网格。
  @override
  void drawGrid(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    KLineDemoDelegateDefaultImplUtil.drawGrid(canvas, size, context);
  }

  /// 绘制主图滚动内容，包括蜡烛和主图指标。
  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    KLineDemoDelegateDefaultImplUtil.drawMainChart(canvas, size, context);
  }

  /// 绘制副图滚动内容，包括 VOL、MACD、KDJ、RSI、WR。
  @override
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    KLineDemoDelegateDefaultImplUtil.drawSecondaryCharts(canvas, size, context);
  }

  /// 构建固定 overlay widget，例如指标标签和底部指标选择栏。
  @override
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
  ) {
    return KLineDemoDelegateDefaultImplUtil.buildOverlayView(
      context,
      chartContext,
    );
  }

  /// 构建长按选中后的详情浮层。
  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
    KLineLayoutNode<KLineModel> selectedNode,
  ) {
    return KLineDemoDelegateDefaultImplUtil.buildSelectionView(
      context,
      chartContext,
      selectedNode,
    );
  }
}
