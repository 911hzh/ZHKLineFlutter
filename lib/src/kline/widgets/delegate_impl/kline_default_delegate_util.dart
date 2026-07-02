import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_data_adapter.dart';
import 'package:kline_flutter/src/kline/widgets/kline_views.dart';

/// 计算副图参与数值映射的内容区域。
Rect kLineDefaultSecondaryContentRect(
  Rect rect, {
  required KLineLayoutConfig layout,
}) {
  final inset = math.min(
    layout.secondaryContentVerticalPadding,
    rect.height / 2,
  );
  return Rect.fromLTRB(
    rect.left,
    rect.top + inset,
    rect.right,
    rect.bottom - inset,
  );
}

/// 将固定视口坐标系中的裁剪区域转换为横向滚动内容坐标系。
Rect kLineDefaultDrawableClipRect(Rect rect, {required double scrollOffset}) {
  return rect.shift(Offset(scrollOffset, 0));
}

/// 默认实现使用的布局节点。
class KLineDefaultLayoutNode<T> extends KLineLayoutNode<T> {
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

typedef KLineIndicatorDrawer<T> =
    void Function(
      Canvas canvas,
      Rect rect,
      KLineChartContext<T> context,
      KLineIndicatorSpec<T> indicator,
    );

/// 默认 delegate 的可复用静态实现工具。
final class KLineDefaultDelegateImplUtil {
  /// 计算默认图表高度。
  static double chartHeight<T>(
    KLineChartContext<T> context, {
    required List<KLineIndicatorSpec<T>> secondaryIndicators,
    required KLineIndicatorHeightGetter<T> indicatorHeight,
  }) {
    return context.layout.mainChartHeight +
        secondaryIndicators.fold<double>(
          0,
          (height, indicator) => height + indicatorHeight(context, indicator),
        ) +
        context.layout.indicatorSelectorHeight;
  }

  /// 根据当前可见区间构建默认布局节点。
  static List<KLineLayoutNode<T>> getLayoutNodes<T>(
    KLineChartContext<T> context,
    List<T> dataSource, {
    required KLineDataAdapter<T> adapter,
    required List<KLineIndicatorSpec<T>> mainIndicators,
  }) {
    final nodes = KLineChartLayoutUtils.buildLayoutNodes(
      context: context,
      dataSource: dataSource,
      visibleRange: context.visibleRange,
    );
    final range = _visiblePriceRange(
      context,
      nodes: nodes,
      adapter: adapter,
      mainIndicators: mainIndicators,
    );
    final rect = _mainContentRect(context);
    final bodyWidth = math.max(
      1.0,
      context.layout.scaledCandleWidth(context.controller.scale),
    );
    return nodes.map((node) {
      final item = node.item;
      return KLineDefaultLayoutNode<T>(
        index: node.index,
        item: item,
        frame: node.frame,
        centerX: _contentX(context, node.centerX),
        bodyWidth: bodyWidth,
        highY: valueToY(adapter.high(item), range, rect),
        lowY: valueToY(adapter.low(item), range, rect),
        openY: valueToY(adapter.open(item), range, rect),
        closeY: valueToY(adapter.close(item), range, rect),
        candleColor:
            _isRising(item, adapter: adapter)
                ? context.theme.candleUpColor
                : context.theme.candleDownColor,
      );
    }).toList();
  }

  /// 绘制固定网格层。
  static void drawGrid<T>(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
    required List<KLineIndicatorSpec<T>> mainIndicators,
    required List<KLineIndicatorSpec<T>> secondaryIndicators,
    required KLineIndicatorHeightGetter<T> indicatorHeight,
  }) {
    final paint =
        Paint()
          ..color = context.theme.gridLineColor
          ..strokeWidth = context.theme.gridStrokeWidth;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      strutStyle: const StrutStyle(fontSize: 8),
    );
    final range = _visiblePriceRange(
      context,
      adapter: adapter,
      mainIndicators: mainIndicators,
    );
    final mainRect = _mainRect(context);
    final contentRect = _mainContentRect(context);
    final lineOffset = context.theme.gridStrokeWidth / 2;

    canvas.drawLine(
      Offset(mainRect.left + lineOffset, mainRect.top),
      Offset(mainRect.right - lineOffset, mainRect.top),
      paint,
    );

    for (var i = 0; i < context.layout.gridHorizontalCount; i++) {
      final y =
          contentRect.top +
          contentRect.height * i / (context.layout.gridHorizontalCount - 1);
      final price =
          i == 0
              ? range.$2
              : i == context.layout.gridHorizontalCount - 1
              ? range.$1
              : range.$2 -
                  (range.$2 - range.$1) *
                      i /
                      (context.layout.gridHorizontalCount - 1);
      canvas.drawLine(
        Offset(mainRect.left + lineOffset, y),
        Offset(mainRect.right - lineOffset, y),
        paint,
      );
      _drawText(
        canvas,
        textPainter,
        price.toStringAsFixed(2),
        Offset(size.width - 50, i == 0 ? y + 1 : y - 12),
        context.theme.textColor,
      );
    }

    final dateLabels = _dateLabels(context, adapter: adapter);
    for (var i = 0; i < context.layout.gridVerticalCount; i++) {
      final x =
          mainRect.left +
          mainRect.width * i / (context.layout.gridVerticalCount - 1);
      final clippedX = x.clamp(
        mainRect.left + lineOffset,
        mainRect.right - lineOffset,
      );
      final snappedX = clippedX.roundToDouble();
      canvas.drawLine(
        Offset(snappedX, mainRect.top),
        Offset(snappedX, contentRect.bottom),
        paint,
      );
      if (i < dateLabels.length) {
        _drawCenteredText(
          canvas,
          textPainter,
          dateLabels[i],
          centerX: snappedX,
          y: mainRect.bottom - (context.layout.contentPadding.bottom + 12) / 2,
          color: context.theme.textColor,
        );
      }
    }

    for (final rect
        in _secondaryRects(
          context,
          secondaryIndicators,
          indicatorHeight: indicatorHeight,
        ).values) {
      canvas.drawLine(
        Offset(rect.left + lineOffset, rect.top),
        Offset(rect.right - lineOffset, rect.top),
        paint,
      );
      canvas.drawLine(
        Offset(rect.left + lineOffset, rect.bottom),
        Offset(rect.right - lineOffset, rect.bottom),
        paint,
      );
      canvas.drawLine(
        Offset(rect.left + lineOffset, rect.bottom - 20),
        Offset(rect.right - lineOffset, rect.bottom - 20),
        paint,
      );

      for (var i = 0; i < context.layout.gridVerticalCount; i++) {
        final x =
            rect.left + rect.width * i / (context.layout.gridVerticalCount - 1);
        final clippedX = x.clamp(
          rect.left + lineOffset,
          rect.right - lineOffset,
        );
        final snappedX = clippedX.roundToDouble();
        canvas.drawLine(
          Offset(snappedX, rect.top),
          Offset(snappedX, rect.bottom),
          paint,
        );
      }
    }
  }

  /// 绘制主图滚动内容。
  static void drawMainChart<T>(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
    required List<KLineIndicatorSpec<T>> mainIndicators,
    required KLineIndicatorDrawer<T> drawIndicator,
  }) {
    final scrollOffset = context.controller.scrollOffset;
    final rect = _mainContentRect(context);
    canvas.save();
    canvas.clipRect(
      kLineDefaultDrawableClipRect(rect, scrollOffset: scrollOffset),
    );
    _drawCandles(canvas, context, adapter: adapter);
    for (final indicator in mainIndicators) {
      if (context.controller.activeIndicatorIds.contains(indicator.id)) {
        drawIndicator(canvas, rect, context, indicator);
      }
    }
    canvas.restore();
  }

  /// 绘制副图滚动内容。
  static void drawSecondaryCharts<T>(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context, {
    required List<KLineIndicatorSpec<T>> secondaryIndicators,
    required KLineIndicatorHeightGetter<T> indicatorHeight,
    required KLineIndicatorDrawer<T> drawIndicator,
  }) {
    final scrollOffset = context.controller.scrollOffset;
    final rects = _secondaryRects(
      context,
      secondaryIndicators,
      indicatorHeight: indicatorHeight,
    );
    for (final entry in rects.entries) {
      final contentRect = kLineDefaultSecondaryContentRect(
        entry.value,
        layout: context.layout,
      );
      canvas.save();
      canvas.clipRect(
        kLineDefaultDrawableClipRect(contentRect, scrollOffset: scrollOffset),
      );
      drawIndicator(canvas, contentRect, context, entry.key);
      canvas.restore();
    }
  }

  /// 构建默认 overlay。
  static Widget? buildOverlayView<T>(
    BuildContext context,
    KLineChartContext<T> chartContext, {
    required KLineDataAdapter<T> adapter,
    required List<KLineIndicatorSpec<T>> mainIndicators,
    required List<KLineIndicatorSpec<T>> secondaryIndicators,
    required KLineIndicatorHeightGetter<T> indicatorHeight,
  }) {
    final selected =
        chartContext.selectedNode?.item ??
        (chartContext.layoutNodes.isNotEmpty
            ? chartContext.layoutNodes.first.item
            : null);
    if (selected == null) return null;

    return Stack(
      children: [
        MainIndicatorLabels<T>(
          context: chartContext,
          selected: selected,
          adapter: adapter,
          indicators: mainIndicators,
        ),
        SecondaryIndicatorLabels<T>(
          context: chartContext,
          selected: selected,
          adapter: adapter,
          indicators: secondaryIndicators,
          indicatorHeight: indicatorHeight,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: KLineDefaultIndicatorSelector<T>(
            context: chartContext,
            mainIndicators: mainIndicators,
            secondaryIndicators: secondaryIndicators,
          ),
        ),
      ],
    );
  }

  /// 构建默认选中详情浮层。
  static Widget? buildSelectionView<T>(
    BuildContext context,
    KLineChartContext<T> chartContext,
    KLineLayoutNode<T> selectedNode, {
    required KLineDataAdapter<T> adapter,
  }) {
    final touchX = chartContext.controller.selectionLocalPosition?.dx ?? 0;
    final showRight = touchX < chartContext.viewportSize.width / 2;
    final entries = adapter.detailEntries(selectedNode.item);
    return Positioned(
      left: showRight ? null : 16,
      right: showRight ? 16 : null,
      top: 16,
      child: KLineSelectionDetailPanel(entries: entries),
    );
  }

  /// 默认指标绘制入口。
  static void drawIndicator<T>(
    Canvas canvas,
    Rect rect,
    KLineChartContext<T> context,
    KLineIndicatorSpec<T> indicator, {
    required KLineDataAdapter<T> adapter,
  }) {
    final renderer = indicator.renderer;
    if (renderer != null) {
      renderer(canvas, rect, context, adapter, indicator);
      return;
    }
    if (indicator.id == KLineDefaultIndicators.volumeId) {
      _drawVolume(canvas, context, rect, indicator, adapter: adapter);
      return;
    }
    if (indicator.id == KLineDefaultIndicators.macdId) {
      _drawMacd(canvas, context, rect, indicator, adapter: adapter);
      return;
    }
    _drawIndicatorLines(
      canvas,
      context,
      rect,
      indicator.series,
      fixedRange: indicatorRange(context, indicator, adapter: adapter),
      adapter: adapter,
    );
  }

  /// 计算副图指标的数值范围。
  static (double min, double max) indicatorRange<T>(
    KLineChartContext<T> context,
    KLineIndicatorSpec<T> indicator, {
    required KLineDataAdapter<T> adapter,
  }) {
    if (indicator.id == KLineDefaultIndicators.volumeId) {
      return _volumeRange(context, indicator, adapter: adapter);
    }
    if (indicator.id == KLineDefaultIndicators.macdId) {
      final dataRange = _indicatorRange(
        context,
        indicator.series,
        adapter: adapter,
      );
      return (math.min(0.0, dataRange.$1), math.max(0.0, dataRange.$2));
    }
    return _indicatorRange(context, indicator.series, adapter: adapter);
  }

  /// 绘制长按选中时的十字线和交点。
  static void drawCrossLine<T>(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
  ) {
    final selected = context.selectedNode;
    final localPosition = context.controller.selectionLocalPosition;
    if (selected == null || localPosition == null) {
      return;
    }

    final x = crossLineContentX(context);
    if (x == null) return;
    if (x < 0 || x > size.width) return;
    final paint =
        Paint()
          ..color = context.theme.crosshairColor
          ..strokeWidth = 1;
    canvas.drawLine(
      Offset(x, context.layout.contentPadding.top),
      Offset(x, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2, localPosition.dy),
      Offset(size.width - 2, localPosition.dy),
      paint,
    );

    final dotPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, localPosition.dy), 3, dotPaint);
  }

  /// 计算内容层十字线的 x 坐标。
  static double? crossLineContentX<T>(KLineChartContext<T> context) {
    return context.selectedNode?.centerX;
  }

  /// 将某个数值按给定范围映射到绘制区域 y 坐标。
  static double valueToY(
    double value,
    (double min, double max) range,
    Rect rect,
  ) {
    final ratio = (value - range.$1) / (range.$2 - range.$1);
    return rect.bottom - ratio * rect.height;
  }

  static Rect _mainRect<T>(KLineChartContext<T> context) {
    final left = context.layout.chartPadding.left;
    final right =
        context.viewportSize.width - context.layout.chartPadding.right;
    return Rect.fromLTWH(
      left,
      0,
      math.max(0, right - left),
      context.layout.mainChartHeight,
    );
  }

  static Rect _mainContentRect<T>(KLineChartContext<T> context) {
    final main = _mainRect(context);
    return Rect.fromLTRB(
      main.left,
      main.top + context.layout.contentPadding.top,
      main.right,
      main.bottom - context.layout.contentPadding.bottom,
    );
  }

  static Map<KLineIndicatorSpec<T>, Rect> _secondaryRects<T>(
    KLineChartContext<T> context,
    List<KLineIndicatorSpec<T>> indicators, {
    required KLineIndicatorHeightGetter<T> indicatorHeight,
  }) {
    final rects = <KLineIndicatorSpec<T>, Rect>{};
    var top = context.layout.mainChartHeight;
    for (final indicator in indicators) {
      final height = indicatorHeight(context, indicator);
      rects[indicator] = Rect.fromLTWH(
        context.layout.chartPadding.left,
        top,
        math.max(
          0,
          context.viewportSize.width - context.layout.chartPadding.horizontal,
        ),
        height,
      );
      top += height;
    }
    return rects;
  }

  static List<String> _dateLabels<T>(
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
  }) {
    if (context.layoutNodes.isEmpty) return const [];
    final labels = <String>[];
    for (var i = 0; i < context.layout.gridVerticalCount; i++) {
      final index =
          (i *
                  (context.layoutNodes.length - 1) /
                  (context.layout.gridVerticalCount - 1))
              .round();
      labels.add(adapter.dateLabel(context.layoutNodes[index].item));
    }
    return labels;
  }

  static void _drawText(
    Canvas canvas,
    TextPainter textPainter,
    String text,
    Offset offset,
    Color color,
  ) {
    textPainter
      ..text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10),
      )
      ..textAlign = TextAlign.left
      ..layout();
    textPainter.paint(canvas, offset);
  }

  static void _drawCenteredText(
    Canvas canvas,
    TextPainter textPainter,
    String text, {
    required double centerX,
    required double y,
    required Color color,
  }) {
    const dateLabelWidth = 70.0;
    textPainter
      ..text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10),
      )
      ..textAlign = TextAlign.center
      ..layout(minWidth: dateLabelWidth, maxWidth: dateLabelWidth);
    final left = centerX - dateLabelWidth / 2;
    textPainter.paint(canvas, Offset(left, y));
  }

  static double _contentX<T>(KLineChartContext<T> context, double x) {
    return x + context.layout.chartPadding.left;
  }

  static (double min, double max) _visiblePriceRange<T>(
    KLineChartContext<T> context, {
    List<KLineLayoutNode<T>>? nodes,
    required KLineDataAdapter<T> adapter,
    required List<KLineIndicatorSpec<T>> mainIndicators,
  }) {
    final layoutNodes = nodes ?? context.layoutNodes;
    if (layoutNodes.isEmpty) return (0, 1);
    var min = adapter.low(layoutNodes.first.item);
    var max = adapter.high(layoutNodes.first.item);
    for (final node in layoutNodes) {
      min = math.min(min, adapter.low(node.item));
      max = math.max(max, adapter.high(node.item));
      for (final indicator in mainIndicators) {
        if (!context.controller.activeIndicatorIds.contains(indicator.id)) {
          continue;
        }
        for (final entry in adapter.mainIndicatorEntries(
          node.item,
          indicator,
        )) {
          final value = entry.value;
          if (value == null) continue;
          min = math.min(min, value);
          max = math.max(max, value);
        }
      }
    }
    if (min == max) return (min - 1, max + 1);
    return (min, max);
  }

  static (double min, double max) _volumeRange<T>(
    KLineChartContext<T> context,
    KLineIndicatorSpec<T> indicator, {
    required KLineDataAdapter<T> adapter,
  }) {
    var max = 0.0;
    for (final node in context.layoutNodes) {
      max = math.max(max, adapter.volume(node.item));
      for (final series in indicator.series) {
        final value = series.valueOf(node.item, adapter);
        if (value != null) max = math.max(max, value);
      }
    }
    if (max <= 0) return (0, 1);
    return (0, max);
  }

  static (double min, double max) _indicatorRange<T>(
    KLineChartContext<T> context,
    List<KLineIndicatorSeries<T>> seriesList, {
    required KLineDataAdapter<T> adapter,
  }) {
    final collected = <double>[];
    for (final node in context.layoutNodes) {
      for (final series in seriesList) {
        final value = series.valueOf(node.item, adapter);
        if (value != null) collected.add(value);
      }
    }
    if (collected.isEmpty) return (-1, 1);
    final min = collected.reduce(math.min);
    final max = collected.reduce(math.max);
    if (min == max) return (min - 1, max + 1);
    return (min, max);
  }

  static bool _isRising<T>(T item, {required KLineDataAdapter<T> adapter}) =>
      adapter.close(item) >= adapter.open(item);

  static void _drawCandles<T>(
    Canvas canvas,
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
  }) {
    final upBodyPath = Path();
    final downBodyPath = Path();
    final upWickPath = Path();
    final downWickPath = Path();
    for (final node in context.layoutNodes) {
      if (node is! KLineDefaultLayoutNode<T>) continue;
      final isRising = _isRising(node.item, adapter: adapter);
      final bodyPath = isRising ? upBodyPath : downBodyPath;
      final wickPath = isRising ? upWickPath : downWickPath;
      wickPath
        ..moveTo(node.centerX, node.highY)
        ..lineTo(node.centerX, node.lowY);
      bodyPath.addRect(
        Rect.fromLTRB(
          node.centerX - node.bodyWidth / 2,
          math.min(node.openY, node.closeY),
          node.centerX + node.bodyWidth / 2,
          math.max(
            math.max(node.openY, node.closeY),
            math.min(node.openY, node.closeY) + 1,
          ),
        ),
      );
    }

    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final wickPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = context.theme.candleStrokeWidth;
    canvas.drawPath(upWickPath, wickPaint..color = context.theme.candleUpColor);
    canvas.drawPath(
      downWickPath,
      wickPaint..color = context.theme.candleDownColor,
    );
    canvas.drawPath(upBodyPath, bodyPaint..color = context.theme.candleUpColor);
    canvas.drawPath(
      downBodyPath,
      bodyPaint..color = context.theme.candleDownColor,
    );
  }

  static void _drawVolume<T>(
    Canvas canvas,
    KLineChartContext<T> context,
    Rect rect,
    KLineIndicatorSpec<T> indicator, {
    required KLineDataAdapter<T> adapter,
  }) {
    final range = indicatorRange(context, indicator, adapter: adapter);
    final maxVolume = range.$2;
    if (maxVolume <= 0) return;
    final upPath = Path();
    final downPath = Path();
    final barWidth = math.max(
      1.0,
      context.layout.scaledCandleWidth(context.controller.scale),
    );
    for (final node in context.layoutNodes) {
      final height = rect.height * (adapter.volume(node.item) / maxVolume);
      final y = rect.bottom - height;
      final centerX = _contentX(context, node.centerX);
      final path = _isRising(node.item, adapter: adapter) ? upPath : downPath;
      path.addRect(Rect.fromLTWH(centerX - barWidth / 2, y, barWidth, height));
    }

    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(upPath, paint..color = context.theme.candleUpColor);
    canvas.drawPath(downPath, paint..color = context.theme.candleDownColor);
    _drawIndicatorLines(
      canvas,
      context,
      rect,
      indicator.series,
      fixedRange: range,
      adapter: adapter,
    );
  }

  static void _drawMacd<T>(
    Canvas canvas,
    KLineChartContext<T> context,
    Rect rect,
    KLineIndicatorSpec<T> indicator, {
    required KLineDataAdapter<T> adapter,
  }) {
    final range = indicatorRange(context, indicator, adapter: adapter);
    final upPath = Path();
    final downPath = Path();
    final barWidth = math.max(
      1,
      context.layout.scaledCandleWidth(context.controller.scale) * 0.6,
    );
    final zeroY = valueToY(0, range, rect);
    for (final node in context.layoutNodes) {
      final macd = adapter.indicatorValue(
        node.item,
        KLineDefaultIndicators.macdValue,
      );
      if (macd == null) continue;
      final valueY = valueToY(macd, range, rect);
      final centerX = _contentX(context, node.centerX);
      final path = macd >= 0 ? upPath : downPath;
      path.addRect(
        Rect.fromLTRB(
          centerX - barWidth / 2,
          math.min(zeroY, valueY),
          centerX + barWidth / 2,
          math.max(zeroY, valueY),
        ),
      );
    }
    final paint = Paint();
    canvas.drawPath(upPath, paint..color = context.theme.candleUpColor);
    canvas.drawPath(downPath, paint..color = context.theme.candleDownColor);
    _drawIndicatorLines(
      canvas,
      context,
      rect,
      indicator.series
          .where((series) => series.id != KLineDefaultIndicators.macdValue)
          .toList(),
      fixedRange: range,
      adapter: adapter,
    );
  }

  static void _drawIndicatorLines<T>(
    Canvas canvas,
    KLineChartContext<T> context,
    Rect rect,
    List<KLineIndicatorSeries<T>> lines, {
    (double min, double max)? fixedRange,
    required KLineDataAdapter<T> adapter,
  }) {
    final range =
        fixedRange ?? _indicatorRange(context, lines, adapter: adapter);
    for (final line in lines) {
      final path = Path();
      var hasStarted = false;
      for (final node in context.layoutNodes) {
        final value = line.valueOf(node.item, adapter);
        if (value == null) {
          hasStarted = false;
          continue;
        }
        final point = Offset(
          _contentX(context, node.centerX),
          valueToY(value, range, rect),
        );
        if (hasStarted) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
          hasStarted = true;
        }
      }
      final paint =
          Paint()
            ..color = context.theme.indicatorColorAt(line.colorIndex)
            ..strokeWidth = context.theme.indicatorStrokeWidth
            ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }
}
