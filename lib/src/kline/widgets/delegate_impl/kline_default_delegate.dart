import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_default_delegate_util.dart';

import '../../delegate/kline_chart_delegate.dart';
import '../../theme/kline_theme.dart';
import 'kline_data_adapter.dart';

/// 计算副图参与数值映射的内容区域。
///
/// 默认上下保留一定 padding，避免柱状图或指标线贴住副图边框。
Rect kLineDefaultSecondaryContentRect(Rect rect, {required KLineLayoutConfig layout}) {
  final inset = math.min(layout.secondaryContentVerticalPadding, rect.height / 2);
  return Rect.fromLTRB(rect.left, rect.top + inset, rect.right, rect.bottom - inset);
}

/// 将固定视口坐标系中的裁剪区域转换为横向滚动内容坐标系。
Rect kLineDefaultDrawableClipRect(Rect rect, {required double scrollOffset}) {
  return rect.shift(Offset(scrollOffset, 0));
}

/// 默认实现使用的布局节点。
///
/// 在基础 [KLineLayoutNode] 上缓存蜡烛中心点、实体宽度、OHLC 对应 y 坐标
/// 和蜡烛颜色，减少绘制阶段的重复计算。
class KLineDefaultLayoutNode<T> extends KLineLayoutNode<T> {
  /// 创建一个默认 K 线布局节点。
  const KLineDefaultLayoutNode({
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
  /// 带图表横向 padding 后的蜡烛中心 x 坐标。
  final double centerX;

  /// 蜡烛实体宽度。
  final double bodyWidth;

  /// 最高价 y 坐标。
  final double highY;

  /// 最低价 y 坐标。
  final double lowY;

  /// 开盘价 y 坐标。
  final double openY;

  /// 收盘价 y 坐标。
  final double closeY;

  /// 当前蜡烛使用的涨跌颜色。
  final Color candleColor;
}

/// 默认 K 线 delegate 的基础实现。
///
/// 该类不直接承载绘制细节，所有默认布局、绘制和 overlay 构建都转发给
/// [KLineDefaultDelegateImplUtil]，便于业务方复用 util 的某一部分能力。
class KLineDefaultDelegateImpl<T> extends KLineChartDelegate<T> {
  /// 创建默认 delegate。
  const KLineDefaultDelegateImpl({required this.adapter, this.onScroll});

  /// 业务模型到默认 K 线字段的适配器。
  final KLineDataAdapter<T> adapter;
  @override
  void drawChart(Canvas canvas, Size size, KLineChartContext<T> context) {
    super.drawChart(canvas, size, context);
    KLineDefaultDelegateImplUtil.drawCrossLine(canvas, size, context);
  }

  /// 用户滚动回调，可用于触发分页加载。
  final void Function(KLineChartContext<T> context, KLineScrollMetrics metrics)? onScroll;

  /// 返回默认图表高度。
  ///
  /// 高度由主图、副图数量和指标选择器高度组成。
  @override
  double chartHeight(KLineChartContext<T> context) {
    return KLineDefaultDelegateImplUtil.chartHeight(context);
  }

  /// 用户滚动时透传给外部回调。
  @override
  void didScroll(KLineChartContext<T> context, KLineScrollMetrics metrics) {
    onScroll?.call(context, metrics);
  }

  /// 构建默认布局节点。
  @override
  List<KLineLayoutNode<T>> getLayoutNodes(KLineChartContext<T> context, List<T> dataSource) {
    return KLineDefaultDelegateImplUtil.getLayoutNodes(context, dataSource, adapter: adapter);
  }

  /// 绘制固定网格层。
  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<T> context) {
    KLineDefaultDelegateImplUtil.drawGrid(canvas, size, context, adapter: adapter);
  }

  /// 绘制主图滚动内容。
  @override
  void drawMainChart(Canvas canvas, Size size, KLineChartContext<T> context) {
    KLineDefaultDelegateImplUtil.drawMainChart(canvas, size, context, adapter: adapter);
  }

  /// 绘制副图滚动内容。
  @override
  void drawSecondaryCharts(Canvas canvas, Size size, KLineChartContext<T> context) {
    KLineDefaultDelegateImplUtil.drawSecondaryCharts(canvas, size, context, adapter: adapter);
  }

  /// 构建默认 overlay，包括指标标签和底部指标选择器。
  @override
  Widget? buildOverlayView(BuildContext context, KLineChartContext<T> chartContext) {
    return KLineDefaultDelegateImplUtil.buildOverlayView(context, chartContext, adapter: adapter);
  }

  /// 构建默认选中详情浮层。
  @override
  Widget? buildSelectionView(BuildContext context, KLineChartContext<T> chartContext, KLineLayoutNode<T> selectedNode) {
    return KLineDefaultDelegateImplUtil.buildSelectionView(context, chartContext, selectedNode, adapter: adapter);
  }
}
