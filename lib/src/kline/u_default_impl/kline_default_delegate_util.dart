import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_line_flutter/k_line_flutter.dart';
import 'package:k_line_flutter/src/kline/u_default_impl/kline_views.dart';

/// 默认 delegate 的可复用实现工具。
///
/// 该类承载默认 K 线的布局、网格、蜡烛、指标、overlay 和选中详情构建逻辑。
/// [KLineDefaultDelegateImpl] 只负责把 delegate 回调转发到这里。
class KLineDefaultDelegateImplUtil<T> {
  /// 创建默认实现工具。
  const KLineDefaultDelegateImplUtil({required this.adapter});

  /// 业务数据适配器，用于读取 OHLCV、日期、指标和详情字段。
  final KLineDataAdapter<T> adapter;

  /// 计算默认图表高度。
  ///
  /// 高度包含主图、当前启用副图和底部指标选择器。
  double chartHeight(KLineChartContext<T> context) {
    return context.layout.mainChartHeight +
        _activeSecondaryTypes(context).length *
            context.layout.secondaryPaneHeight +
        context.layout.indicatorSelectorHeight;
  }

  /// 根据当前可见区间构建默认布局节点。
  ///
  /// 该方法会预先计算蜡烛高低开收的 y 坐标，绘制阶段直接消费节点。
  List<KLineLayoutNode<T>> getLayoutNodes(
    KLineChartContext<T> context,
    List<T> dataSource,
  ) {
    final nodes = KLineChartLayoutUtils.buildLayoutNodes(
      context: context,
      dataSource: dataSource,
      visibleRange: context.visibleRange,
    );
    final range = _visiblePriceRange(context, nodes: nodes);
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
        highY: _valueToY(adapter.high(item), range, rect),
        lowY: _valueToY(adapter.low(item), range, rect),
        openY: _valueToY(adapter.open(item), range, rect),
        closeY: _valueToY(adapter.close(item), range, rect),
        candleColor:
            _isRising(item)
                ? context.theme.candleUpColor
                : context.theme.candleDownColor,
      );
    }).toList();
  }

  /// 绘制固定网格层。
  ///
  /// 网格层不随横向内容滚动，包括主图网格、价格文字、日期文字、副图边界
  /// 和长按十字线。
  void drawGrid(Canvas canvas, Size size, KLineChartContext<T> context) {
    final paint =
        Paint()
          ..color = context.theme.gridLineColor
          ..strokeWidth = context.theme.gridStrokeWidth;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final range = _visiblePriceRange(context);
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

    final dateLabels = _dateLabels(context);
    for (var i = 0; i < context.layout.gridVerticalCount; i++) {
      final x =
          mainRect.left +
          mainRect.width * i / (context.layout.gridVerticalCount - 1);
      final clippedX = x.clamp(
        mainRect.left + lineOffset,
        mainRect.right - lineOffset,
      );
      canvas.drawLine(
        Offset(clippedX, mainRect.top),
        Offset(clippedX, contentRect.bottom),
        paint,
      );
      if (i < dateLabels.length) {
        _drawText(
          canvas,
          textPainter,
          dateLabels[i],
          Offset(
            (x - 20).clamp(0, size.width - 52),
            mainRect.bottom - (_contentBottomPadding + 12) / 2,
          ),
          context.theme.textColor,
        );
      }
    }

    for (final rect in _secondaryRects(context).values) {
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
        canvas.drawLine(
          Offset(clippedX, rect.top),
          Offset(clippedX, rect.bottom),
          paint,
        );
      }
    }

    _drawCrossLine(canvas, size, context);
  }

  /// 绘制主图滚动内容。
  ///
  /// 默认包含蜡烛与 MA/EMA/BOLL 等主图指标线。
  void drawMainChart(Canvas canvas, Size size, KLineChartContext<T> context) {
    final scrollOffset = context.controller.scrollOffset;
    canvas.save();
    canvas.clipRect(
      kLineDefaultDrawableClipRect(
        _mainContentRect(context),
        scrollOffset: scrollOffset,
      ),
    );
    _drawCandles(canvas, context);
    _drawMainIndicators(canvas, context);
    canvas.restore();
  }

  /// 绘制副图滚动内容。
  ///
  /// 根据当前启用的副图指标依次绘制 VOL、MACD、KDJ、RSI、WR。
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
  ) {
    final scrollOffset = context.controller.scrollOffset;
    for (final entry in _secondaryRects(context).entries) {
      canvas.save();
      canvas.clipRect(
        kLineDefaultDrawableClipRect(
          kLineDefaultSecondaryContentRect(entry.value, layout: context.layout),
          scrollOffset: scrollOffset,
        ),
      );
      _drawSecondary(canvas, context, entry.key, entry.value);
      canvas.restore();
    }
  }

  /// 构建默认 overlay。
  ///
  /// 默认包含主图指标标签、副图指标标签和底部指标选择器。
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<T> chartContext,
  ) {
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
        ),
        SecondaryIndicatorLabels<T>(
          context: chartContext,
          selected: selected,
          adapter: adapter,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: KLineDefaultIndicatorSelector(context: chartContext),
        ),
      ],
    );
  }

  /// 构建默认选中详情浮层。
  ///
  /// 根据触点所在屏幕左右位置决定详情框显示在左侧还是右侧。
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<T> chartContext,
    KLineLayoutNode<T> selectedNode,
  ) {
    final touchX = chartContext.controller.selectionLocalPosition?.dx ?? 0;
    final showRight = touchX < chartContext.viewportSize.width / 2;
    final detailText = adapter
        .detailEntries(selectedNode.item)
        .map((entry) => '${entry.label}: ${entry.value}')
        .join('\n');
    return Positioned(
      left: showRight ? null : 16,
      right: showRight ? 16 : null,
      top: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(detailText, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  static const _contentTopPadding = 30.0;
  static const _contentBottomPadding = 30.0;

  /// 判断当前 K 线是否上涨。
  bool _isRising(T item) => adapter.close(item) >= adapter.open(item);

  /// 批量绘制蜡烛实体和影线。
  ///
  /// 使用涨跌两个 Path 聚合绘制，减少逐根蜡烛调用 Canvas API 的次数。
  void _drawCandles(Canvas canvas, KLineChartContext<T> context) {
    final upBodyPath = Path();
    final downBodyPath = Path();
    final upWickPath = Path();
    final downWickPath = Path();
    for (final node in context.layoutNodes) {
      if (node is! KLineDefaultLayoutNode<T>) continue;
      final isRising = _isRising(node.item);
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

  /// 绘制主图指标线。
  void _drawMainIndicators(Canvas canvas, KLineChartContext<T> context) {
    final active = context.controller.activeIndicatorIds;
    final rect = _mainContentRect(context);
    final range = _visiblePriceRange(context);
    if (active.contains(KLineDefaultIndicatorType.ma.name)) {
      _drawIndicatorLines(canvas, context, rect, [
        (KLineDefaultIndicatorValue.ma5, context.theme.indicatorColorAt(0)),
        (KLineDefaultIndicatorValue.ma10, context.theme.indicatorColorAt(1)),
        (KLineDefaultIndicatorValue.ma30, context.theme.indicatorColorAt(2)),
      ], fixedRange: range);
    }
    if (active.contains(KLineDefaultIndicatorType.ema.name)) {
      _drawIndicatorLines(canvas, context, rect, [
        (KLineDefaultIndicatorValue.ema5, context.theme.indicatorColorAt(3)),
        (KLineDefaultIndicatorValue.ema10, context.theme.indicatorColorAt(4)),
        (KLineDefaultIndicatorValue.ema30, context.theme.indicatorColorAt(5)),
      ], fixedRange: range);
    }
    if (active.contains(KLineDefaultIndicatorType.boll.name)) {
      _drawIndicatorLines(canvas, context, rect, [
        (
          KLineDefaultIndicatorValue.bollUpper,
          context.theme.indicatorColorAt(0),
        ),
        (
          KLineDefaultIndicatorValue.bollMiddle,
          context.theme.indicatorColorAt(1),
        ),
        (
          KLineDefaultIndicatorValue.bollLower,
          context.theme.indicatorColorAt(2),
        ),
      ], fixedRange: range);
    }
  }

  /// 根据副图指标类型分发具体绘制逻辑。
  void _drawSecondary(
    Canvas canvas,
    KLineChartContext<T> context,
    KLineDefaultIndicatorType type,
    Rect rect,
  ) {
    final contentRect = kLineDefaultSecondaryContentRect(
      rect,
      layout: context.layout,
    );
    switch (type) {
      case KLineDefaultIndicatorType.volume:
        _drawVolume(canvas, context, contentRect);
      case KLineDefaultIndicatorType.macd:
        _drawMacd(canvas, context, contentRect);
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
          fixedRange: _indicatorRange(context, [
            KLineDefaultIndicatorValue.k,
            KLineDefaultIndicatorValue.d,
            KLineDefaultIndicatorValue.j,
          ]),
        );
      case KLineDefaultIndicatorType.rsi:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (
              KLineDefaultIndicatorValue.rsi6,
              context.theme.indicatorColorAt(3),
            ),
            (
              KLineDefaultIndicatorValue.rsi12,
              context.theme.indicatorColorAt(4),
            ),
            (
              KLineDefaultIndicatorValue.rsi24,
              context.theme.indicatorColorAt(1),
            ),
          ],
          fixedRange: _indicatorRange(context, [
            KLineDefaultIndicatorValue.rsi6,
            KLineDefaultIndicatorValue.rsi12,
            KLineDefaultIndicatorValue.rsi24,
          ]),
        );
      case KLineDefaultIndicatorType.wr:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (KLineDefaultIndicatorValue.wr6, context.theme.indicatorColorAt(3)),
            (
              KLineDefaultIndicatorValue.wr10,
              context.theme.indicatorColorAt(4),
            ),
            (
              KLineDefaultIndicatorValue.wr14,
              context.theme.indicatorColorAt(1),
            ),
          ],
          fixedRange: _indicatorRange(context, [
            KLineDefaultIndicatorValue.wr6,
            KLineDefaultIndicatorValue.wr10,
            KLineDefaultIndicatorValue.wr14,
          ]),
        );
      case KLineDefaultIndicatorType.ma:
      case KLineDefaultIndicatorType.ema:
      case KLineDefaultIndicatorType.boll:
        break;
    }
  }

  /// 绘制成交量柱状图和成交量均线。
  void _drawVolume(Canvas canvas, KLineChartContext<T> context, Rect rect) {
    final maxVolume = context.layoutNodes.fold<double>(
      0,
      (value, node) => math.max(value, adapter.volume(node.item)),
    );
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
      final path = _isRising(node.item) ? upPath : downPath;
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
        (
          KLineDefaultIndicatorValue.volumeMA5,
          context.theme.indicatorColorAt(1),
        ),
        (
          KLineDefaultIndicatorValue.volumeMA10,
          context.theme.indicatorColorAt(3),
        ),
      ],
      fixedRange: (0, maxVolume),
    );
  }

  /// 绘制 MACD 柱状图和 DIF/DEA 指标线。
  void _drawMacd(Canvas canvas, KLineChartContext<T> context, Rect rect) {
    final dataRange = _indicatorRange(context, [
      KLineDefaultIndicatorValue.macd,
      KLineDefaultIndicatorValue.dif,
      KLineDefaultIndicatorValue.dea,
    ]);
    final range = (math.min(0.0, dataRange.$1), math.max(0.0, dataRange.$2));
    final upPath = Path();
    final downPath = Path();
    final barWidth = math.max(
      1,
      context.layout.scaledCandleWidth(context.controller.scale) * 0.6,
    );
    final zeroY = _valueToY(0, range, rect);
    for (final node in context.layoutNodes) {
      final macd = adapter.indicatorValue(
        node.item,
        KLineDefaultIndicatorValue.macd,
      );
      if (macd == null) continue;
      final valueY = _valueToY(macd, range, rect);
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
    _drawIndicatorLines(canvas, context, rect, [
      (KLineDefaultIndicatorValue.dif, context.theme.indicatorColorAt(1)),
      (KLineDefaultIndicatorValue.dea, context.theme.indicatorColorAt(3)),
    ], fixedRange: range);
  }

  /// 批量绘制一组指标折线。
  ///
  /// 每条指标线会被聚合为一个 Path，遇到 null 指标值时自动断线。
  void _drawIndicatorLines(
    Canvas canvas,
    KLineChartContext<T> context,
    Rect rect,
    List<(KLineDefaultIndicatorValue, Color)> lines, {
    (double min, double max)? fixedRange,
  }) {
    final range = fixedRange ?? _visiblePriceRange(context);
    for (final line in lines) {
      final path = Path();
      var hasStarted = false;
      for (final node in context.layoutNodes) {
        final value = adapter.indicatorValue(node.item, line.$1);
        if (value == null) {
          hasStarted = false;
          continue;
        }
        final point = Offset(
          _contentX(context, node.centerX),
          _valueToY(value, range, rect),
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
            ..color = line.$2
            ..strokeWidth = context.theme.indicatorStrokeWidth
            ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  /// 绘制长按选中时的十字线和交点。
  void _drawCrossLine(Canvas canvas, Size size, KLineChartContext<T> context) {
    final selected = context.selectedNode;
    final localPosition = context.controller.selectionLocalPosition;
    final contentPosition = context.controller.selectionContentPosition;
    if (selected == null || localPosition == null || contentPosition == null) {
      return;
    }

    final x = _contentX(
      context,
      contentPosition.dx - context.controller.scrollOffset,
    );
    if (x < 0 || x > size.width) return;
    final paint =
        Paint()
          ..color = context.theme.crosshairColor
          ..strokeWidth = 1;
    canvas.drawLine(
      Offset(x, _contentTopPadding),
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

  /// 主图完整区域，包含顶部指标文案和底部时间轴空间。
  Rect _mainRect(KLineChartContext<T> context) {
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

  /// 主图实际参与价格映射和蜡烛绘制的内容区域。
  Rect _mainContentRect(KLineChartContext<T> context) {
    final main = _mainRect(context);
    return Rect.fromLTRB(
      main.left,
      main.top + _contentTopPadding,
      main.right,
      main.bottom - _contentBottomPadding,
    );
  }

  /// 当前启用的副图指标类型列表。
  List<KLineDefaultIndicatorType> _activeSecondaryTypes(
    KLineChartContext<T> context,
  ) {
    return KLineDefaultIndicatorType.secondaryTypes
        .where(
          (type) => context.controller.activeIndicatorIds.contains(type.name),
        )
        .toList();
  }

  /// 计算每个副图模块对应的矩形区域。
  Map<KLineDefaultIndicatorType, Rect> _secondaryRects(
    KLineChartContext<T> context,
  ) {
    final rects = <KLineDefaultIndicatorType, Rect>{};
    final types = _activeSecondaryTypes(context);
    for (var i = 0; i < types.length; i++) {
      rects[types[i]] = Rect.fromLTWH(
        context.layout.chartPadding.left,
        context.layout.mainChartHeight + context.layout.secondaryPaneHeight * i,
        math.max(
          0,
          context.viewportSize.width - context.layout.chartPadding.horizontal,
        ),
        context.layout.secondaryPaneHeight,
      );
    }
    return rects;
  }

  /// 依据当前可见节点抽取底部日期标签。
  List<String> _dateLabels(KLineChartContext<T> context) {
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

  /// 使用 [TextPainter] 绘制文本。
  void _drawText(
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
      ..layout();
    textPainter.paint(canvas, offset);
  }

  /// 将滚动内容坐标转换为带图表横向 padding 的画布坐标。
  double _contentX(KLineChartContext<T> context, double x) {
    return x + context.layout.chartPadding.left;
  }

  /// 计算当前可见 K 线的价格范围。
  (double min, double max) _visiblePriceRange(
    KLineChartContext<T> context, {
    List<KLineLayoutNode<T>>? nodes,
  }) {
    final layoutNodes = nodes ?? context.layoutNodes;
    if (layoutNodes.isEmpty) return (0, 1);
    var min = adapter.low(layoutNodes.first.item);
    var max = adapter.high(layoutNodes.first.item);
    for (final node in layoutNodes) {
      min = math.min(min, adapter.low(node.item));
      max = math.max(max, adapter.high(node.item));
    }
    if (min == max) return (min - 1, max + 1);
    return (min, max);
  }

  /// 计算当前可见 K 线中指定指标集合的数值范围。
  (double min, double max) _indicatorRange(
    KLineChartContext<T> context,
    List<KLineDefaultIndicatorValue> values,
  ) {
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
  double _valueToY(double value, (double min, double max) range, Rect rect) {
    final ratio = (value - range.$1) / (range.$2 - range.$1);
    return rect.bottom - ratio * rect.height;
  }
}
