import 'package:flutter/material.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_data_adapter.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_default_delegate_util.dart';

export 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_default_delegate_util.dart'
    show
        KLineDefaultLayoutNode,
        kLineDefaultDrawableClipRect,
        kLineDefaultSecondaryContentRect;

/// 默认 K 线 delegate 的基础实现。
///
/// 该类不直接承载绘制细节，所有默认布局、绘制和 overlay 构建都转发给
/// [KLineDefaultDelegateImplUtil]，便于业务方复用 util 的某一部分能力。
class KLineDefaultDelegateImpl<T> extends KLineChartDelegate<T> {
  /// 创建默认 delegate。
  const KLineDefaultDelegateImpl({
    required this.adapter,
    this.mainIndicators,
    this.secondaryIndicators,
    this.onScroll,
  });

  /// 业务模型到默认 K 线字段的适配器。
  final KLineDataAdapter<T> adapter;

  /// 可选择的主图指标；不传时使用默认 MA/EMA/BOLL。
  final List<KLineIndicatorSpec<T>>? mainIndicators;

  /// 可选择的副图指标；不传时使用默认 VOL/MACD/KDJ/RSI/WR。
  final List<KLineIndicatorSpec<T>>? secondaryIndicators;

  @override
  void drawChart(Canvas canvas, Size size, KLineChartContext<T> context) {
    super.drawChart(canvas, size, context);
    KLineDefaultDelegateImplUtil.drawCrossLine(canvas, size, context);
  }

  /// 用户滚动回调，可用于触发分页加载。
  final void Function(KLineChartContext<T> context, KLineScrollMetrics metrics)?
  onScroll;

  /// 返回默认图表高度。
  ///
  /// 高度由主图、副图数量和指标选择器高度组成。
  @override
  double chartHeight(KLineChartContext<T> context) {
    return KLineDefaultDelegateImplUtil.chartHeight(
      context,
      secondaryIndicators: activeSecondaryIndicators(context),
      indicatorHeight: indicatorHeight,
    );
  }

  /// 用户滚动时透传给外部回调。
  @override
  void didScroll(KLineChartContext<T> context, KLineScrollMetrics metrics) {
    onScroll?.call(context, metrics);
  }

  /// 构建默认布局节点。
  @override
  List<KLineLayoutNode<T>> getLayoutNodes(
    KLineChartContext<T> context,
    List<T> dataSource,
  ) {
    return KLineDefaultDelegateImplUtil.getLayoutNodes(
      context,
      dataSource,
      adapter: adapter,
      mainIndicators: availableMainIndicators(context),
    );
  }

  /// 绘制固定网格层。
  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<T> context) {
    KLineDefaultDelegateImplUtil.drawGrid(
      canvas,
      size,
      context,
      adapter: adapter,
      mainIndicators: availableMainIndicators(context),
      secondaryIndicators: activeSecondaryIndicators(context),
      indicatorHeight: indicatorHeight,
    );
  }

  /// 绘制主图滚动内容。
  @override
  void drawMainChart(Canvas canvas, Size size, KLineChartContext<T> context) {
    KLineDefaultDelegateImplUtil.drawMainChart(
      canvas,
      size,
      context,
      adapter: adapter,
      mainIndicators: availableMainIndicators(context),
      drawIndicator: drawIndicator,
    );
  }

  /// 绘制副图滚动内容。
  @override
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
  ) {
    KLineDefaultDelegateImplUtil.drawSecondaryCharts(
      canvas,
      size,
      context,
      secondaryIndicators: activeSecondaryIndicators(context),
      indicatorHeight: indicatorHeight,
      drawIndicator: drawIndicator,
    );
  }

  /// 构建默认 overlay，包括指标标签和底部指标选择器。
  @override
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<T> chartContext,
  ) {
    return KLineDefaultDelegateImplUtil.buildOverlayView(
      context,
      chartContext,
      adapter: adapter,
      mainIndicators: availableMainIndicators(chartContext),
      secondaryIndicators: availableSecondaryIndicators(chartContext),
      indicatorHeight: indicatorHeight,
    );
  }

  /// 构建默认选中详情浮层。
  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<T> chartContext,
    KLineLayoutNode<T> selectedNode,
  ) {
    return KLineDefaultDelegateImplUtil.buildSelectionView(
      context,
      chartContext,
      selectedNode,
      adapter: adapter,
    );
  }

  /// 当前默认 delegate 可选择的主图指标。
  List<KLineIndicatorSpec<T>> availableMainIndicators(
    KLineChartContext<T> context,
  ) {
    return mainIndicators ?? KLineDefaultIndicators.main<T>();
  }

  /// 当前默认 delegate 可选择的副图指标。
  List<KLineIndicatorSpec<T>> availableSecondaryIndicators(
    KLineChartContext<T> context,
  ) {
    return secondaryIndicators ?? KLineDefaultIndicators.secondary<T>();
  }

  /// 当前已启用的副图指标。
  List<KLineIndicatorSpec<T>> activeSecondaryIndicators(
    KLineChartContext<T> context,
  ) {
    final active = context.controller.activeIndicatorIds;
    return availableSecondaryIndicators(
      context,
    ).where((indicator) => active.contains(indicator.id)).toList();
  }

  /// 指定副图指标的高度。
  double indicatorHeight(
    KLineChartContext<T> context,
    KLineIndicatorSpec<T> indicator,
  ) {
    return indicator.height ?? context.layout.secondaryPaneHeight;
  }

  /// 绘制指定指标。
  void drawIndicator(
    Canvas canvas,
    Rect rect,
    KLineChartContext<T> context,
    KLineIndicatorSpec<T> indicator,
  ) {
    KLineDefaultDelegateImplUtil.drawIndicator(
      canvas,
      rect,
      context,
      indicator,
      adapter: adapter,
    );
  }
}
