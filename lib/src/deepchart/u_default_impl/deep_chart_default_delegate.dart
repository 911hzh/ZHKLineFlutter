import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../delegate/deep_chart_delegate.dart';
import '../model/deep_depth_entry.dart';

/// 深度图默认绘制代理。
///
/// 默认实现负责绘制网格、累计深度面积图、右侧累计数量轴、底部价格轴、
/// 底部边界线和可选图例。业务方可以继承该类覆盖部分方法。
class DeepChartDefaultDelegate<T> extends DeepChartDelegate<T> {
  /// 创建默认深度图绘制代理。
  const DeepChartDefaultDelegate({this.showLegend = true, this.watermark});

  /// 是否显示顶部买盘/卖盘图例。
  final bool showLegend;

  /// 默认水印文字，为空时不绘制水印。
  final String? watermark;

  /// 绘制固定网格、坐标轴文本和水印。
  @override
  void drawGrid(Canvas canvas, Size size, DeepChartContext<T> context) {
    final rect = context.layout.contentRectFor(size);
    final paint =
        Paint()
          ..color = context.theme.gridLineColor
          ..strokeWidth = context.theme.gridStrokeWidth;

    final lines = DeepChartDefaultLayoutUtils.buildGridLines(
      contentRect: rect,
      horizontalCount: context.layout.gridHorizontalCount,
      verticalCount: context.layout.gridVerticalCount,
    );
    for (final line in lines) {
      canvas.drawLine(line.start, line.end, paint);
    }

    _drawAxisLabels(canvas, size, context);
    _drawWatermark(canvas, rect, context);
  }

  /// 绘制买盘/卖盘累计深度面积图和底部边界线。
  @override
  void drawChart(Canvas canvas, Size size, DeepChartContext<T> context) {
    final rect = context.layout.contentRectFor(size);
    _drawSide(canvas, rect, context.nodes.bids, context.theme.bidColor);
    _drawSide(canvas, rect, context.nodes.asks, context.theme.askColor);
    _drawBottomSeparator(canvas, rect, context);
  }

  /// 构建顶部固定图例。
  @override
  Widget? buildOverlayView(
    BuildContext context,
    DeepChartContext<T> chartContext,
  ) {
    if (!showLegend) return null;
    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: chartContext.theme.bidColor, label: '买盘'),
          const SizedBox(width: 28),
          _LegendItem(color: chartContext.theme.askColor, label: '卖盘'),
        ],
      ),
    );
  }

  /// 绘制单侧累计深度曲线和渐变填充。
  void _drawSide(
    Canvas canvas,
    Rect rect,
    List<DeepDepthNode> nodes,
    Color color,
  ) {
    final positioned = nodes.where((node) => node.position != null).toList();
    if (positioned.isEmpty) return;

    final linePath =
        Path()..moveTo(
          positioned.first.position!.dx,
          positioned.first.position!.dy,
        );
    for (final node in positioned.skip(1)) {
      linePath.lineTo(node.position!.dx, node.position!.dy);
    }

    final fillPath =
        Path.from(linePath)
          ..lineTo(positioned.last.position!.dx, rect.bottom)
          ..lineTo(positioned.first.position!.dx, rect.bottom)
          ..close();
    final shader = ui.Gradient.linear(
      Offset(0, rect.top),
      Offset(0, rect.bottom),
      [color.withValues(alpha: 0.18), color.withValues(alpha: 0.04)],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  /// 绘制底部价格标签和右侧累计数量标签。
  void _drawAxisLabels(Canvas canvas, Size size, DeepChartContext<T> context) {
    final nodes = context.nodes;
    if (nodes.isEmpty) return;
    final rect = context.layout.contentRectFor(size);
    final textStyle = TextStyle(color: context.theme.textColor, fontSize: 11);
    final bottomTextStyle = TextStyle(
      color: context.theme.textColor,
      fontSize: 9,
    );

    final priceLayouts =
        DeepChartDefaultLayoutUtils.buildBottomPriceLabelLayouts(
          contentRect: rect,
          chartWidth: size.width,
          rowTop: context.layout.mainHeight,
          rowHeight: context.layout.bottomHeight,
          bottomPadding: context.layout.contentPadding.bottom,
          priceLabelCount: context.layout.priceLabelCount,
          verticalCount: context.layout.gridVerticalCount,
        );
    for (var i = 0; i < priceLayouts.length; i++) {
      final t =
          context.layout.priceLabelCount == 1
              ? 0.0
              : i / (context.layout.priceLabelCount - 1);
      final price = nodes.minPrice + (nodes.maxPrice - nodes.minPrice) * t;
      _paintTextInRect(
        canvas,
        price.toStringAsFixed(2),
        priceLayouts[i].rect,
        bottomTextStyle,
        priceLayouts[i].textAlign,
      );
    }

    final maxSize = nodes.maxCumulativeSize;
    final rightOffsets = DeepChartDefaultLayoutUtils.buildRightAxisLabelOffsets(
      contentRect: rect,
      chartWidth: size.width,
      labelHeight: 11,
      horizontalCount: context.layout.gridHorizontalCount,
    );
    for (var i = 0; i < rightOffsets.length; i++) {
      final t =
          context.layout.gridHorizontalCount == 0
              ? 0.0
              : i / context.layout.gridHorizontalCount;
      final value = maxSize * (1 - t);
      _paintText(canvas, _formatSize(value), rightOffsets[i], textStyle);
    }
  }

  /// 绘制默认水印。
  void _drawWatermark(Canvas canvas, Rect rect, DeepChartContext<T> context) {
    final text = watermark;
    if (text == null || text.isEmpty) return;
    _paintText(
      canvas,
      text,
      Offset(rect.left + 32, rect.bottom - 44),
      TextStyle(
        color: context.theme.watermarkColor,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  /// 在指定偏移绘制单行文本。
  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  /// 在指定矩形内绘制文本，并按给定横向方式对齐。
  ///
  /// 垂直方向使用字体基线计算视觉中心，避免简单使用段落高度导致偏移。
  void _paintTextInRect(
    Canvas canvas,
    String text,
    Rect rect,
    TextStyle style,
    TextAlign align,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(minWidth: rect.width, maxWidth: rect.width);
    final lineMetrics = painter.computeLineMetrics();
    final top =
        lineMetrics.isEmpty
            ? rect.top + (rect.height - painter.height) / 2
            : _visualCenteredTextTop(rect, lineMetrics.first);
    final offset = Offset(rect.left, top);
    painter.paint(canvas, offset);
  }

  /// 根据首行字体指标计算视觉居中的绘制 top。
  double _visualCenteredTextTop(Rect rect, LineMetrics line) {
    final baseline = rect.center.dy + (line.ascent - line.descent) / 2;
    return baseline - line.baseline;
  }

  /// 绘制底部最终边界线。
  void _drawBottomSeparator(
    Canvas canvas,
    Rect rect,
    DeepChartContext<T> context,
  ) {
    final paint =
        Paint()
          ..color = context.theme.gridLineColor
          ..strokeWidth = context.theme.gridStrokeWidth;
    final line = DeepChartDefaultLayoutUtils.buildBottomSeparatorLine(
      contentRect: rect,
      totalHeight: context.layout.mainHeight + context.layout.bottomHeight,
      strokeWidth: context.theme.gridStrokeWidth,
    );
    canvas.drawLine(line.start, line.end, paint);
  }

  /// 格式化右侧累计数量刻度。
  String _formatSize(double value) {
    if (value >= 1000) return value.toStringAsFixed(0);
    if (value >= 100) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }
}

/// 默认图例项。
class _LegendItem extends StatelessWidget {
  /// 创建图例项。
  const _LegendItem({required this.color, required this.label});

  /// 图例色块颜色。
  final Color color;

  /// 图例文案。
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: const SizedBox(width: 12, height: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A8A8A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
