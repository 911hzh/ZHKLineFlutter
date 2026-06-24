import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';
import 'package:kline_flutter/src/kline/u_default_impl/kline_views.dart';

/// 默认 delegate 的可复用静态实现工具。
///
/// 该类承载默认 K 线的布局、网格、蜡烛、指标、overlay 和选中详情构建逻辑。
/// 需要读取业务模型字段的方法会显式接收 [KLineDataAdapter]。
final class KLineDefaultDelegateImplUtil {
  /// 计算默认图表高度。
  ///
  /// 高度包含主图、当前启用副图和底部指标选择器。
  static double chartHeight<T>(KLineChartContext<T> context) {
    return context.layout.mainChartHeight +
        _activeSecondaryTypes(context).length * context.layout.secondaryPaneHeight +
        context.layout.indicatorSelectorHeight;
  }

  /// 根据当前可见区间构建默认布局节点。
  ///
  /// 该方法会预先计算蜡烛高低开收的 y 坐标，绘制阶段直接消费节点。
  static List<KLineLayoutNode<T>> getLayoutNodes<T>(
    KLineChartContext<T> context,
    List<T> dataSource, {
    required KLineDataAdapter<T> adapter,
  }) {
    final nodes = KLineChartLayoutUtils.buildLayoutNodes(
      context: context,
      dataSource: dataSource,
      visibleRange: context.visibleRange,
    );
    final range = _visiblePriceRange(context, nodes: nodes, adapter: adapter);
    final rect = _mainContentRect(context);
    final bodyWidth = math.max(1.0, context.layout.scaledCandleWidth(context.controller.scale));
    return nodes.map((node) {
      final item = node.item;
      return KLineDefaultLayoutNode<T>(
        index: node.index,
        item: item,
        frame: node.frame,
        centerX: _contentX(context, node.centerX),
        bodyWidth: bodyWidth,
        highY: _valueToY(adapter.high(item), range, rect),
        lowY: _valueToY(adapter.low(item), range, rect),
        openY: _valueToY(adapter.open(item), range, rect),
        closeY: _valueToY(adapter.close(item), range, rect),
        candleColor: _isRising(item, adapter: adapter) ? context.theme.candleUpColor : context.theme.candleDownColor,
      );
    }).toList();
  }

  /// 绘制固定网格层。
  ///
  /// 网格层不随横向内容滚动，包括主图网格、价格文字、日期文字、副图边界
  /// 和长按十字线。
  static void drawGrid<T>(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
  }) {
    final paint =
        Paint()
          ..color = context.theme.gridLineColor
          ..strokeWidth = context.theme.gridStrokeWidth;
    final textPainter = TextPainter(textDirection: TextDirection.ltr, strutStyle: const StrutStyle(fontSize: 8));
    final range = _visiblePriceRange(context, adapter: adapter);
    final mainRect = _mainRect(context);
    final contentRect = _mainContentRect(context);
    final lineOffset = context.theme.gridStrokeWidth / 2;

    canvas.drawLine(
      Offset(mainRect.left + lineOffset, mainRect.top),
      Offset(mainRect.right - lineOffset, mainRect.top),
      paint,
    );

    for (var i = 0; i < context.layout.gridHorizontalCount; i++) {
      final y = contentRect.top + contentRect.height * i / (context.layout.gridHorizontalCount - 1);
      final price =
          i == 0
              ? range.$2
              : i == context.layout.gridHorizontalCount - 1
              ? range.$1
              : range.$2 - (range.$2 - range.$1) * i / (context.layout.gridHorizontalCount - 1);
      canvas.drawLine(Offset(mainRect.left + lineOffset, y), Offset(mainRect.right - lineOffset, y), paint);
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
      final x = mainRect.left + mainRect.width * i / (context.layout.gridVerticalCount - 1);
      final clippedX = x.clamp(mainRect.left + lineOffset, mainRect.right - lineOffset);
      final snappedX = clippedX.roundToDouble();
      canvas.drawLine(Offset(snappedX, mainRect.top), Offset(snappedX, contentRect.bottom), paint);
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

    for (final rect in _secondaryRects(context).values) {
      canvas.drawLine(Offset(rect.left + lineOffset, rect.top), Offset(rect.right - lineOffset, rect.top), paint);
      canvas.drawLine(Offset(rect.left + lineOffset, rect.bottom), Offset(rect.right - lineOffset, rect.bottom), paint);
      canvas.drawLine(
        Offset(rect.left + lineOffset, rect.bottom - 20),
        Offset(rect.right - lineOffset, rect.bottom - 20),
        paint,
      );

      for (var i = 0; i < context.layout.gridVerticalCount; i++) {
        final x = rect.left + rect.width * i / (context.layout.gridVerticalCount - 1);
        final clippedX = x.clamp(rect.left + lineOffset, rect.right - lineOffset);
        final snappedX = clippedX.roundToDouble();
        canvas.drawLine(Offset(snappedX, rect.top), Offset(snappedX, rect.bottom), paint);
      }
    }
  }

  /// 绘制主图滚动内容。
  ///
  /// 默认包含蜡烛与 MA/EMA/BOLL 等主图指标线。
  static void drawMainChart<T>(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
  }) {
    final scrollOffset = context.controller.scrollOffset;
    canvas.save();
    canvas.clipRect(kLineDefaultDrawableClipRect(_mainContentRect(context), scrollOffset: scrollOffset));
    _drawCandles(canvas, context, adapter: adapter);
    _drawMainIndicators(canvas, context, adapter: adapter);
    canvas.restore();
  }

  /// 绘制副图滚动内容。
  ///
  /// 根据当前启用的副图指标依次绘制 VOL、MACD、KDJ、RSI、WR。
  static void drawSecondaryCharts<T>(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
  }) {
    final scrollOffset = context.controller.scrollOffset;
    for (final entry in _secondaryRects(context).entries) {
      canvas.save();
      canvas.clipRect(
        kLineDefaultDrawableClipRect(
          kLineDefaultSecondaryContentRect(entry.value, layout: context.layout),
          scrollOffset: scrollOffset,
        ),
      );
      _drawSecondary(canvas, context, entry.key, entry.value, adapter: adapter);
      canvas.restore();
    }
  }

  /// 构建默认 overlay。
  ///
  /// 默认包含主图指标标签、副图指标标签和底部指标选择器。
  static Widget? buildOverlayView<T>(
    BuildContext context,
    KLineChartContext<T> chartContext, {
    required KLineDataAdapter<T> adapter,
  }) {
    final selected =
        chartContext.selectedNode?.item ??
        (chartContext.layoutNodes.isNotEmpty ? chartContext.layoutNodes.first.item : null);
    if (selected == null) return null;

    return Stack(
      children: [
        MainIndicatorLabels<T>(context: chartContext, selected: selected, adapter: adapter),
        SecondaryIndicatorLabels<T>(context: chartContext, selected: selected, adapter: adapter),
        Positioned(left: 0, right: 0, bottom: 0, child: KLineDefaultIndicatorSelector(context: chartContext)),
      ],
    );
  }

  /// 构建默认选中详情浮层。
  ///
  /// 根据触点所在屏幕左右位置决定详情框显示在左侧还是右侧。
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

  /// 计算默认副图指标的数值范围。
  ///
  /// 该范围必须覆盖同一副图内所有会被绘制的数值，例如 VOL 需要同时包含
  /// 成交量柱和成交量均线，MACD 需要同时包含柱状值、DIF、DEA 和 0 基线。
  static (double min, double max) secondaryIndicatorRange<T>(
    KLineChartContext<T> context,
    KLineDefaultIndicatorType type, {
    required KLineDataAdapter<T> adapter,
  }) {
    return switch (type) {
      KLineDefaultIndicatorType.volume => _volumeRange(context, adapter: adapter),
      KLineDefaultIndicatorType.macd => _macdRange(context, adapter: adapter),
      KLineDefaultIndicatorType.kdj => _indicatorRange(context, [
        KLineDefaultIndicatorValue.k,
        KLineDefaultIndicatorValue.d,
        KLineDefaultIndicatorValue.j,
      ], adapter: adapter),
      KLineDefaultIndicatorType.rsi => _indicatorRange(context, [
        KLineDefaultIndicatorValue.rsi6,
        KLineDefaultIndicatorValue.rsi12,
        KLineDefaultIndicatorValue.rsi24,
      ], adapter: adapter),
      KLineDefaultIndicatorType.wr => _indicatorRange(context, [
        KLineDefaultIndicatorValue.wr6,
        KLineDefaultIndicatorValue.wr10,
        KLineDefaultIndicatorValue.wr14,
      ], adapter: adapter),
      KLineDefaultIndicatorType.ma || KLineDefaultIndicatorType.ema || KLineDefaultIndicatorType.boll => (-1, 1),
    };
  }

  /// 判断当前 K 线是否上涨。
  static bool _isRising<T>(T item, {required KLineDataAdapter<T> adapter}) => adapter.close(item) >= adapter.open(item);

  /// 批量绘制蜡烛实体和影线。
  ///
  /// 使用涨跌两个 Path 聚合绘制，减少逐根蜡烛调用 Canvas API 的次数。
  static void _drawCandles<T>(Canvas canvas, KLineChartContext<T> context, {required KLineDataAdapter<T> adapter}) {
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
          math.max(math.max(node.openY, node.closeY), math.min(node.openY, node.closeY) + 1),
        ),
      );
    }

    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final wickPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = context.theme.candleStrokeWidth;
    canvas.drawPath(upWickPath, wickPaint..color = context.theme.candleUpColor);
    canvas.drawPath(downWickPath, wickPaint..color = context.theme.candleDownColor);
    canvas.drawPath(upBodyPath, bodyPaint..color = context.theme.candleUpColor);
    canvas.drawPath(downBodyPath, bodyPaint..color = context.theme.candleDownColor);
  }

  /// 绘制主图指标线。
  static void _drawMainIndicators<T>(
    Canvas canvas,
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
  }) {
    final active = context.controller.activeIndicatorIds;
    final rect = _mainContentRect(context);
    final range = _visiblePriceRange(context, adapter: adapter);
    if (active.contains(KLineDefaultIndicatorType.ma.name)) {
      _drawIndicatorLines(
        canvas,
        context,
        rect,
        [
          (KLineDefaultIndicatorValue.ma5, context.theme.indicatorColorAt(0)),
          (KLineDefaultIndicatorValue.ma10, context.theme.indicatorColorAt(1)),
          (KLineDefaultIndicatorValue.ma30, context.theme.indicatorColorAt(2)),
        ],
        fixedRange: range,
        adapter: adapter,
      );
    }
    if (active.contains(KLineDefaultIndicatorType.ema.name)) {
      _drawIndicatorLines(
        canvas,
        context,
        rect,
        [
          (KLineDefaultIndicatorValue.ema5, context.theme.indicatorColorAt(3)),
          (KLineDefaultIndicatorValue.ema10, context.theme.indicatorColorAt(4)),
          (KLineDefaultIndicatorValue.ema30, context.theme.indicatorColorAt(5)),
        ],
        fixedRange: range,
        adapter: adapter,
      );
    }
    if (active.contains(KLineDefaultIndicatorType.boll.name)) {
      _drawIndicatorLines(
        canvas,
        context,
        rect,
        [
          (KLineDefaultIndicatorValue.bollUpper, context.theme.indicatorColorAt(0)),
          (KLineDefaultIndicatorValue.bollMiddle, context.theme.indicatorColorAt(1)),
          (KLineDefaultIndicatorValue.bollLower, context.theme.indicatorColorAt(2)),
        ],
        fixedRange: range,
        adapter: adapter,
      );
    }
  }

  /// 根据副图指标类型分发具体绘制逻辑。
  static void _drawSecondary<T>(
    Canvas canvas,
    KLineChartContext<T> context,
    KLineDefaultIndicatorType type,
    Rect rect, {
    required KLineDataAdapter<T> adapter,
  }) {
    final contentRect = kLineDefaultSecondaryContentRect(rect, layout: context.layout);
    switch (type) {
      case KLineDefaultIndicatorType.volume:
        _drawVolume(canvas, context, contentRect, adapter: adapter);
      case KLineDefaultIndicatorType.macd:
        _drawMacd(canvas, context, contentRect, adapter: adapter);
      case KLineDefaultIndicatorType.kdj:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (KLineDefaultIndicatorValue.k, context.theme.indicatorColorAt(1)),
            (KLineDefaultIndicatorValue.d, context.theme.indicatorColorAt(3)),
            (KLineDefaultIndicatorValue.j, context.theme.indicatorColorAt(2)),
          ],
          fixedRange: secondaryIndicatorRange(context, type, adapter: adapter),
          adapter: adapter,
        );
      case KLineDefaultIndicatorType.rsi:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (KLineDefaultIndicatorValue.rsi6, context.theme.indicatorColorAt(3)),
            (KLineDefaultIndicatorValue.rsi12, context.theme.indicatorColorAt(4)),
            (KLineDefaultIndicatorValue.rsi24, context.theme.indicatorColorAt(1)),
          ],
          fixedRange: secondaryIndicatorRange(context, type, adapter: adapter),
          adapter: adapter,
        );
      case KLineDefaultIndicatorType.wr:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (KLineDefaultIndicatorValue.wr6, context.theme.indicatorColorAt(3)),
            (KLineDefaultIndicatorValue.wr10, context.theme.indicatorColorAt(4)),
            (KLineDefaultIndicatorValue.wr14, context.theme.indicatorColorAt(1)),
          ],
          fixedRange: secondaryIndicatorRange(context, type, adapter: adapter),
          adapter: adapter,
        );
      case KLineDefaultIndicatorType.ma:
      case KLineDefaultIndicatorType.ema:
      case KLineDefaultIndicatorType.boll:
        break;
    }
  }

  /// 绘制成交量柱状图和成交量均线。
  static void _drawVolume<T>(
    Canvas canvas,
    KLineChartContext<T> context,
    Rect rect, {
    required KLineDataAdapter<T> adapter,
  }) {
    final range = secondaryIndicatorRange(context, KLineDefaultIndicatorType.volume, adapter: adapter);
    final maxVolume = range.$2;
    if (maxVolume <= 0) return;
    final upPath = Path();
    final downPath = Path();
    final barWidth = math.max(1.0, context.layout.scaledCandleWidth(context.controller.scale));
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
      [
        (KLineDefaultIndicatorValue.volumeMA5, context.theme.indicatorColorAt(1)),
        (KLineDefaultIndicatorValue.volumeMA10, context.theme.indicatorColorAt(3)),
      ],
      fixedRange: range,
      adapter: adapter,
    );
  }

  /// 绘制 MACD 柱状图和 DIF/DEA 指标线。
  static void _drawMacd<T>(
    Canvas canvas,
    KLineChartContext<T> context,
    Rect rect, {
    required KLineDataAdapter<T> adapter,
  }) {
    final range = secondaryIndicatorRange(context, KLineDefaultIndicatorType.macd, adapter: adapter);
    final upPath = Path();
    final downPath = Path();
    final barWidth = math.max(1, context.layout.scaledCandleWidth(context.controller.scale) * 0.6);
    final zeroY = _valueToY(0, range, rect);
    for (final node in context.layoutNodes) {
      final macd = adapter.indicatorValue(node.item, KLineDefaultIndicatorValue.macd);
      if (macd == null) continue;
      final valueY = _valueToY(macd, range, rect);
      final centerX = _contentX(context, node.centerX);
      final path = macd >= 0 ? upPath : downPath;
      path.addRect(
        Rect.fromLTRB(centerX - barWidth / 2, math.min(zeroY, valueY), centerX + barWidth / 2, math.max(zeroY, valueY)),
      );
    }
    final paint = Paint();
    canvas.drawPath(upPath, paint..color = context.theme.candleUpColor);
    canvas.drawPath(downPath, paint..color = context.theme.candleDownColor);
    _drawIndicatorLines(
      canvas,
      context,
      rect,
      [
        (KLineDefaultIndicatorValue.dif, context.theme.indicatorColorAt(1)),
        (KLineDefaultIndicatorValue.dea, context.theme.indicatorColorAt(3)),
      ],
      fixedRange: range,
      adapter: adapter,
    );
  }

  /// 批量绘制一组指标折线。
  ///
  /// 每条指标线会被聚合为一个 Path，遇到 null 指标值时自动断线。
  static void _drawIndicatorLines<T>(
    Canvas canvas,
    KLineChartContext<T> context,
    Rect rect,
    List<(KLineDefaultIndicatorValue, Color)> lines, {
    (double min, double max)? fixedRange,
    required KLineDataAdapter<T> adapter,
  }) {
    final range = fixedRange ?? _visiblePriceRange(context, adapter: adapter);
    for (final line in lines) {
      final path = Path();
      var hasStarted = false;
      for (final node in context.layoutNodes) {
        final value = adapter.indicatorValue(node.item, line.$1);
        if (value == null) {
          hasStarted = false;
          continue;
        }
        final point = Offset(_contentX(context, node.centerX), _valueToY(value, range, rect));
        if (hasStarted) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
          hasStarted = true;
        }
      }
      final paint =
          Paint()
            ..color = line.$2
            ..strokeWidth = context.theme.indicatorStrokeWidth
            ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  /// 绘制长按选中时的十字线和交点。
  static void drawCrossLine<T>(Canvas canvas, Size size, KLineChartContext<T> context) {
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
    canvas.drawLine(Offset(x, context.layout.contentPadding.top), Offset(x, size.height), paint);
    canvas.drawLine(Offset(2, localPosition.dy), Offset(size.width - 2, localPosition.dy), paint);

    final dotPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, localPosition.dy), 3, dotPaint);
  }

  /// 计算内容层十字线的 x 坐标。
  ///
  /// [drawChart] 在横向滚动内容坐标系中绘制，十字线需要直接使用选中节点的
  /// 内容坐标，而不是再减去 [KLineController.scrollOffset]。
  static double? crossLineContentX<T>(KLineChartContext<T> context) {
    return context.selectedNode?.centerX;
  }

  /// 主图完整区域，包含顶部指标文案和底部时间轴空间。
  static Rect _mainRect<T>(KLineChartContext<T> context) {
    final left = context.layout.chartPadding.left;
    final right = context.viewportSize.width - context.layout.chartPadding.right;
    return Rect.fromLTWH(left, 0, math.max(0, right - left), context.layout.mainChartHeight);
  }

  /// 主图实际参与价格映射和蜡烛绘制的内容区域。
  static Rect _mainContentRect<T>(KLineChartContext<T> context) {
    final main = _mainRect(context);
    return Rect.fromLTRB(
      main.left,
      main.top + context.layout.contentPadding.top,
      main.right,
      main.bottom - context.layout.contentPadding.bottom,
    );
  }

  /// 当前启用的副图指标类型列表。
  static List<KLineDefaultIndicatorType> _activeSecondaryTypes<T>(KLineChartContext<T> context) {
    return KLineDefaultIndicatorType.secondaryTypes
        .where((type) => context.controller.activeIndicatorIds.contains(type.name))
        .toList();
  }

  /// 计算每个副图模块对应的矩形区域。
  static Map<KLineDefaultIndicatorType, Rect> _secondaryRects<T>(KLineChartContext<T> context) {
    final rects = <KLineDefaultIndicatorType, Rect>{};
    final types = _activeSecondaryTypes(context);
    for (var i = 0; i < types.length; i++) {
      rects[types[i]] = Rect.fromLTWH(
        context.layout.chartPadding.left,
        context.layout.mainChartHeight + context.layout.secondaryPaneHeight * i,
        math.max(0, context.viewportSize.width - context.layout.chartPadding.horizontal),
        context.layout.secondaryPaneHeight,
      );
    }
    return rects;
  }

  /// 依据当前可见节点抽取底部日期标签。
  static List<String> _dateLabels<T>(KLineChartContext<T> context, {required KLineDataAdapter<T> adapter}) {
    if (context.layoutNodes.isEmpty) return const [];
    final labels = <String>[];
    for (var i = 0; i < context.layout.gridVerticalCount; i++) {
      final index = (i * (context.layoutNodes.length - 1) / (context.layout.gridVerticalCount - 1)).round();
      labels.add(adapter.dateLabel(context.layoutNodes[index].item));
    }
    return labels;
  }

  /// 使用 [TextPainter] 绘制文本。
  static void _drawText(Canvas canvas, TextPainter textPainter, String text, Offset offset, Color color) {
    textPainter
      ..text = TextSpan(text: text, style: TextStyle(color: color, fontSize: 10))
      ..textAlign = TextAlign.left
      ..layout();
    textPainter.paint(canvas, offset);
  }

  /// 按指定中心 x 坐标绘制文本，并限制在水平边界内。
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
      ..text = TextSpan(text: text, style: TextStyle(color: color, fontSize: 10))
      ..textAlign = TextAlign.center
      ..layout(minWidth: dateLabelWidth, maxWidth: dateLabelWidth);
    final left = centerX - dateLabelWidth / 2;
    textPainter.paint(canvas, Offset(left, y));
  }

  /// 将滚动内容坐标转换为带图表横向 padding 的画布坐标。
  static double _contentX<T>(KLineChartContext<T> context, double x) {
    return x + context.layout.chartPadding.left;
  }

  /// 计算当前可见 K 线的价格范围。
  static (double min, double max) _visiblePriceRange<T>(
    KLineChartContext<T> context, {
    List<KLineLayoutNode<T>>? nodes,
    required KLineDataAdapter<T> adapter,
  }) {
    final layoutNodes = nodes ?? context.layoutNodes;
    if (layoutNodes.isEmpty) return (0, 1);
    var min = adapter.low(layoutNodes.first.item);
    var max = adapter.high(layoutNodes.first.item);
    for (final node in layoutNodes) {
      min = math.min(min, adapter.low(node.item));
      max = math.max(max, adapter.high(node.item));
      for (final type in KLineDefaultIndicatorType.mainTypes) {
        if (!context.controller.activeIndicatorIds.contains(type.name)) {
          continue;
        }
        for (final entry in adapter.mainIndicatorEntries(node.item, type)) {
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

  /// 计算当前可见 K 线中指定指标集合的数值范围。
  static (double min, double max) _volumeRange<T>(
    KLineChartContext<T> context, {
    required KLineDataAdapter<T> adapter,
  }) {
    var max = 0.0;
    for (final node in context.layoutNodes) {
      max = math.max(max, adapter.volume(node.item));
      for (final value in [KLineDefaultIndicatorValue.volumeMA5, KLineDefaultIndicatorValue.volumeMA10]) {
        final indicator = adapter.indicatorValue(node.item, value);
        if (indicator != null) max = math.max(max, indicator);
      }
    }
    if (max <= 0) return (0, 1);
    return (0, max);
  }

  /// 计算 MACD 副图范围，包含柱状值、DIF、DEA 与 0 基线。
  static (double min, double max) _macdRange<T>(KLineChartContext<T> context, {required KLineDataAdapter<T> adapter}) {
    final dataRange = _indicatorRange(context, [
      KLineDefaultIndicatorValue.macd,
      KLineDefaultIndicatorValue.dif,
      KLineDefaultIndicatorValue.dea,
    ], adapter: adapter);
    return (math.min(0.0, dataRange.$1), math.max(0.0, dataRange.$2));
  }

  /// 计算当前可见 K 线中指定指标集合的数值范围。
  static (double min, double max) _indicatorRange<T>(
    KLineChartContext<T> context,
    List<KLineDefaultIndicatorValue> values, {
    required KLineDataAdapter<T> adapter,
  }) {
    final collected = <double>[];
    for (final node in context.layoutNodes) {
      for (final value in values) {
        final indicator = adapter.indicatorValue(node.item, value);
        if (indicator != null) collected.add(indicator);
      }
    }
    if (collected.isEmpty) return (-1, 1);
    final min = collected.reduce(math.min);
    final max = collected.reduce(math.max);
    if (min == max) return (min - 1, max + 1);
    return (min, max);
  }

  /// 将某个数值按给定范围映射到绘制区域 y 坐标。
  static double _valueToY(double value, (double min, double max) range, Rect rect) {
    final ratio = (value - range.$1) / (range.$2 - range.$1);
    return rect.bottom - ratio * rect.height;
  }
}
