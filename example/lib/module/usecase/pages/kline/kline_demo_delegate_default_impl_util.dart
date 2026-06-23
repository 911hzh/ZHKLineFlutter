// ignore_for_file: file_names

part of 'KLineDemoPage.dart';

/// K 线 Demo delegate 的默认实现工具类。
///
/// 使用者可以按需复用这里的类方法，也可以在自定义 delegate 中只替换某几个方法。
class KLineDemoDelegateDefaultImplUtil {
  const KLineDemoDelegateDefaultImplUtil._();

  static const _contentTopPadding = 30.0;
  static const _contentBottomPadding = 30.0;

  /// 依据当前启用的副图数量计算完整图表高度。
  static double chartHeight(KLineChartContext<KLineModel> context) {
    return context.layout.mainChartHeight +
        _activeSecondaryTypes(context).length *
            context.layout.secondaryPaneHeight +
        context.layout.indicatorSelectorHeight;
  }

  /// 根据当前可见数据预计算蜡烛坐标，绘制阶段直接消费 layout node。
  static List<KLineLayoutNode<KLineModel>> getLayoutNodes(
    KLineChartContext<KLineModel> context,
    List<KLineModel> dataSource,
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
      final model = node.item;
      return _KLineDemoLayoutNode(
        index: node.index,
        item: node.item,
        frame: node.frame,
        centerX: _contentX(context, node.centerX),
        bodyWidth: bodyWidth,
        highY: _valueToY(model.high, range, rect),
        lowY: _valueToY(model.low, range, rect),
        openY: _valueToY(model.open, range, rect),
        closeY: _valueToY(model.close, range, rect),
        candleColor: model.close >= model.open
            ? context.theme.candleUpColor
            : context.theme.candleDownColor,
      );
    }).toList();
  }

  /// 绘制固定网格层，包括主图边界、价格轴、日期轴和副图网格。
  static void drawGrid(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final paint = Paint()
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
      final price = i == 0
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
      canvas.drawLine(
        Offset(
          x.clamp(mainRect.left + lineOffset, mainRect.right - lineOffset),
          mainRect.top,
        ),
        Offset(
          x.clamp(mainRect.left + lineOffset, mainRect.right - lineOffset),
          contentRect.bottom,
        ),
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

    for (final entry in _secondaryRects(context).entries) {
      final rect = entry.value;
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

  /// 绘制主图滚动内容，包括蜡烛和主图指标。
  static void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final scrollOffset = context.controller.scrollOffset;
    canvas.save();
    canvas.clipRect(
      kLineDemoDrawableClipRect(
        _mainContentRect(context),
        scrollOffset: scrollOffset,
      ),
    );
    _drawCandles(canvas, context);
    _drawMainIndicators(canvas, context);
    canvas.restore();
  }

  /// 绘制副图滚动内容，包括 VOL、MACD、KDJ、RSI、WR。
  static void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final scrollOffset = context.controller.scrollOffset;
    for (final entry in _secondaryRects(context).entries) {
      canvas.save();
      canvas.clipRect(
        kLineDemoDrawableClipRect(
          kLineDemoSecondaryContentRect(entry.value),
          scrollOffset: scrollOffset,
        ),
      );
      _drawSecondary(canvas, context, entry.key, entry.value);
      canvas.restore();
    }
  }

  /// 构建固定 overlay widget，例如指标标签和底部指标选择栏。
  static Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
  ) {
    final selected =
        chartContext.selectedNode?.item ??
        (chartContext.layoutNodes.isNotEmpty
            ? chartContext.layoutNodes.first.item
            : null);
    if (selected == null) return null;

    return Stack(
      children: [
        _MainIndicatorLabels(context: chartContext, selected: selected),
        _SecondaryIndicatorLabels(context: chartContext, selected: selected),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _IndicatorSelector(context: chartContext),
        ),
      ],
    );
  }

  /// 构建长按选中后的详情浮层。
  static Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
    KLineLayoutNode<KLineModel> selectedNode,
  ) {
    final candle = selectedNode.item;
    final touchX = chartContext.controller.selectionLocalPosition?.dx ?? 0;
    final showRight = touchX < chartContext.viewportSize.width / 2;
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
          child: Text(
            '时间: ${candle.dateString}\n'
            '开: ${candle.open.toStringAsFixed(2)}\n'
            '高: ${candle.high.toStringAsFixed(2)}\n'
            '低: ${candle.low.toStringAsFixed(2)}\n'
            '收: ${candle.close.toStringAsFixed(2)}\n'
            '量: ${candle.volume.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  /// 批量绘制蜡烛，按涨跌颜色聚合 Path，减少逐根蜡烛的 draw 调用。
  static void _drawCandles(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
  ) {
    final upBodyPath = Path();
    final downBodyPath = Path();
    final upWickPath = Path();
    final downWickPath = Path();
    for (final node in context.layoutNodes) {
      if (node is! _KLineDemoLayoutNode) continue;
      final isRising = node.item.close >= node.item.open;
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
    final wickPaint = Paint()
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

  /// 根据当前启用的主图指标绘制 MA/EMA/BOLL 线。
  static void _drawMainIndicators(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
  ) {
    final active = context.controller.activeIndicatorIds;
    final rect = _mainContentRect(context);
    final range = _visiblePriceRange(context);
    if (active.contains(KLineTechnicalIndicatorType.ma.name)) {
      _drawIndicatorLines(canvas, context, rect, [
        (_IndicatorValueExtractor.ma5, context.theme.indicatorColorAt(0)),
        (_IndicatorValueExtractor.ma10, context.theme.indicatorColorAt(1)),
        (_IndicatorValueExtractor.ma30, context.theme.indicatorColorAt(2)),
      ], fixedRange: range);
    }
    if (active.contains(KLineTechnicalIndicatorType.ema.name)) {
      _drawIndicatorLines(canvas, context, rect, [
        (_IndicatorValueExtractor.ema5, context.theme.indicatorColorAt(3)),
        (_IndicatorValueExtractor.ema10, context.theme.indicatorColorAt(4)),
        (_IndicatorValueExtractor.ema30, context.theme.indicatorColorAt(5)),
      ], fixedRange: range);
    }
    if (active.contains(KLineTechnicalIndicatorType.boll.name)) {
      _drawIndicatorLines(canvas, context, rect, [
        (_IndicatorValueExtractor.bollUpper, context.theme.indicatorColorAt(0)),
        (
          _IndicatorValueExtractor.bollMiddle,
          context.theme.indicatorColorAt(1),
        ),
        (_IndicatorValueExtractor.bollLower, context.theme.indicatorColorAt(2)),
      ], fixedRange: range);
    }
  }

  /// 分发副图指标绘制，保证每类指标使用自己的数值范围。
  static void _drawSecondary(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    KLineTechnicalIndicatorType type,
    Rect rect,
  ) {
    final contentRect = kLineDemoSecondaryContentRect(rect);
    switch (type) {
      case KLineTechnicalIndicatorType.volume:
        _drawVolume(canvas, context, contentRect);
      case KLineTechnicalIndicatorType.macd:
        _drawMacd(canvas, context, contentRect);
      case KLineTechnicalIndicatorType.kdj:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (_IndicatorValueExtractor.k, context.theme.indicatorColorAt(1)),
            (_IndicatorValueExtractor.d, context.theme.indicatorColorAt(3)),
            (_IndicatorValueExtractor.j, context.theme.indicatorColorAt(2)),
          ],
          fixedRange: _indicatorRange(context, [
            _IndicatorValueExtractor.k,
            _IndicatorValueExtractor.d,
            _IndicatorValueExtractor.j,
          ]),
        );
      case KLineTechnicalIndicatorType.rsi:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (_IndicatorValueExtractor.rsi6, context.theme.indicatorColorAt(3)),
            (_IndicatorValueExtractor.rsi12, context.theme.indicatorColorAt(4)),
            (_IndicatorValueExtractor.rsi24, context.theme.indicatorColorAt(1)),
          ],
          fixedRange: _indicatorRange(context, [
            _IndicatorValueExtractor.rsi6,
            _IndicatorValueExtractor.rsi12,
            _IndicatorValueExtractor.rsi24,
          ]),
        );
      case KLineTechnicalIndicatorType.wr:
        _drawIndicatorLines(
          canvas,
          context,
          contentRect,
          [
            (_IndicatorValueExtractor.wr6, context.theme.indicatorColorAt(3)),
            (_IndicatorValueExtractor.wr10, context.theme.indicatorColorAt(4)),
            (_IndicatorValueExtractor.wr14, context.theme.indicatorColorAt(1)),
          ],
          fixedRange: _indicatorRange(context, [
            _IndicatorValueExtractor.wr6,
            _IndicatorValueExtractor.wr10,
            _IndicatorValueExtractor.wr14,
          ]),
        );
      case KLineTechnicalIndicatorType.ma:
      case KLineTechnicalIndicatorType.ema:
      case KLineTechnicalIndicatorType.boll:
        break;
    }
  }

  /// 绘制 VOL 柱子和成交量均线。
  static void _drawVolume(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    Rect rect,
  ) {
    final maxVolume = context.layoutNodes.fold<double>(
      0,
      (value, node) => math.max(value, node.item.volume),
    );
    if (maxVolume <= 0) return;
    final upPath = Path();
    final downPath = Path();
    final barWidth = math.max(
      1.0,
      context.layout.scaledCandleWidth(context.controller.scale),
    );
    for (final node in context.layoutNodes) {
      final height = (rect.height * (node.item.volume / maxVolume)).toDouble();
      final y = rect.bottom - height;
      final centerX = _contentX(context, node.centerX);
      final path = node.item.isRising ? upPath : downPath;
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
        (_IndicatorValueExtractor.volumeMA5, context.theme.indicatorColorAt(1)),
        (
          _IndicatorValueExtractor.volumeMA10,
          context.theme.indicatorColorAt(3),
        ),
      ],
      fixedRange: (0, maxVolume),
    );
  }

  /// 绘制 MACD 柱子、DIF/DEA 线，并确保 0 轴参与范围计算。
  static void _drawMacd(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    Rect rect,
  ) {
    final dataRange = _indicatorRange(context, [
      _IndicatorValueExtractor.macd,
      _IndicatorValueExtractor.dif,
      _IndicatorValueExtractor.dea,
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
      final macd = node.item.kLineTechnicalIndicatorsModel?.macd;
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
      (_IndicatorValueExtractor.dif, context.theme.indicatorColorAt(1)),
      (_IndicatorValueExtractor.dea, context.theme.indicatorColorAt(3)),
    ], fixedRange: range);
  }

  /// 按整条 Path 批量绘制指标折线。
  static void _drawIndicatorLines(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    Rect rect,
    List<(_IndicatorValueExtractor, Color)> lines, {
    (double min, double max)? fixedRange,
  }) {
    final range = fixedRange ?? _visiblePriceRange(context);
    for (final line in lines) {
      final path = Path();
      var hasStarted = false;
      for (final node in context.layoutNodes) {
        final value = line.$1.value(node.item.kLineTechnicalIndicatorsModel);
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
      final paint = Paint()
        ..color = line.$2
        ..strokeWidth = context.theme.indicatorStrokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  /// 绘制长按选中时的十字线和交点圆点。
  static void _drawCrossLine(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
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
    final paint = Paint()
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

    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, localPosition.dy), 3, dotPaint);
  }

  /// 主图完整区域，包含顶部指标文字和底部日期文字空间。
  static Rect _mainRect(KLineChartContext<KLineModel> context) {
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
  static Rect _mainContentRect(KLineChartContext<KLineModel> context) {
    final main = _mainRect(context);
    return Rect.fromLTRB(
      main.left,
      main.top + _contentTopPadding,
      main.right,
      main.bottom - _contentBottomPadding,
    );
  }

  /// 当前启用的副图类型列表。
  static List<KLineTechnicalIndicatorType> _activeSecondaryTypes(
    KLineChartContext<KLineModel> context,
  ) {
    return KLineTechnicalIndicatorType.secondTypes
        .where(
          (type) => context.controller.activeIndicatorIds.contains(type.name),
        )
        .toList();
  }

  /// 计算每个副图模块在固定网格层中的区域。
  static Map<KLineTechnicalIndicatorType, Rect> _secondaryRects(
    KLineChartContext<KLineModel> context,
  ) {
    final rects = <KLineTechnicalIndicatorType, Rect>{};
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

  /// 从当前可见 K 线中抽取底部日期标签。
  static List<String> _dateLabels(KLineChartContext<KLineModel> context) {
    if (context.layoutNodes.isEmpty) return const [];
    final labels = <String>[];
    for (var i = 0; i < context.layout.gridVerticalCount; i++) {
      final index =
          (i *
                  (context.layoutNodes.length - 1) /
                  (context.layout.gridVerticalCount - 1))
              .round();
      labels.add(context.layoutNodes[index].item.dateString);
    }
    return labels;
  }

  /// Canvas 文本绘制工具，复用 TextPainter 降低临时对象创建。
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
      ..layout();
    textPainter.paint(canvas, offset);
  }

  /// 将滚动内容坐标转换为带图表横向 padding 的画布坐标。
  static double _contentX(KLineChartContext<KLineModel> context, double x) {
    return x + context.layout.chartPadding.left;
  }

  /// 计算当前可见 K 线的价格范围。
  static (double min, double max) _visiblePriceRange(
    KLineChartContext<KLineModel> context, {
    List<KLineLayoutNode<KLineModel>>? nodes,
  }) {
    final layoutNodes = nodes ?? context.layoutNodes;
    if (layoutNodes.isEmpty) return (0, 1);
    var min = layoutNodes.first.item.low;
    var max = layoutNodes.first.item.high;
    for (final node in layoutNodes) {
      min = math.min(min, node.item.low);
      max = math.max(max, node.item.high);
    }
    if (min == max) return (min - 1, max + 1);
    return (min, max);
  }

  /// 计算当前可见 K 线中指定指标的数值范围。
  static (double min, double max) _indicatorRange(
    KLineChartContext<KLineModel> context,
    List<_IndicatorValueExtractor> extractors,
  ) {
    final values = <double>[];
    for (final node in context.layoutNodes) {
      for (final extractor in extractors) {
        final value = extractor.value(node.item.kLineTechnicalIndicatorsModel);
        if (value != null) values.add(value);
      }
    }
    if (values.isEmpty) return (-1, 1);
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    if (min == max) return (min - 1, max + 1);
    return (min, max);
  }

  /// 将某个数值按指定范围映射到绘制区域内的 y 坐标。
  static double _valueToY(
    double value,
    (double min, double max) range,
    Rect rect,
  ) {
    final ratio = (value - range.$1) / (range.$2 - range.$1);
    return rect.bottom - ratio * rect.height;
  }
}
