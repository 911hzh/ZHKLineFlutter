// ignore_for_file: file_names

// K 线 Demo 绘制代理：复刻旧 Demo 的网格、蜡烛、指标和交互覆盖层绘制。
part of 'KLineDemoPage.dart';

/// Demo 专用 layout node，保存蜡烛绘制需要的坐标和样式。
class _KLineDemoLayoutNode extends KLineLayoutNode<KLineModel> {
  const _KLineDemoLayoutNode({
    required super.visibleItem,
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

  static const _contentTopPadding = 30.0;
  static const _contentBottomPadding = 30.0;

  /// 依据当前启用的副图数量计算完整图表高度。
  @override
  double chartHeight(KLineChartContext<KLineModel> context) {
    return context.layout.mainChartHeight +
        _activeSecondaryTypes(context).length *
            context.layout.secondaryPaneHeight +
        context.layout.indicatorSelectorHeight;
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
  ) {
    final range = _visiblePriceRange(context);
    final rect = _mainContentRect(context);
    final bodyWidth = math.max(
      1.0,
      context.layout.scaledCandleWidth(context.controller.scale),
    );
    return context.visibleItems.map((item) {
      final model = item.item;
      return _KLineDemoLayoutNode(
        visibleItem: item,
        frame: item.frame,
        centerX: _contentX(context, item.centerX),
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
  @override
  void drawGrid(
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
  }

  /// 绘制预计算布局节点；如果不是 Demo 节点则回退到默认 drawItem。
  @override
  void drawLayoutNode(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
    KLineLayoutNode<KLineModel> node,
  ) {
    if (node is! _KLineDemoLayoutNode) {
      super.drawLayoutNode(canvas, size, context, node);
      return;
    }

    final scrollOffset = context.controller.scrollOffset;
    canvas.save();
    canvas.clipRect(
      kLineDemoDrawableClipRect(
        _mainContentRect(context),
        scrollOffset: scrollOffset,
      ),
    );
    _drawCandleNode(canvas, context, node);
    _drawMainIndicators(canvas, context, node.visibleItem);
    canvas.restore();

    for (final entry in _secondaryRects(context).entries) {
      canvas.save();
      canvas.clipRect(
        kLineDemoDrawableClipRect(
          kLineDemoSecondaryContentRect(entry.value),
          scrollOffset: scrollOffset,
        ),
      );
      _drawSecondary(canvas, context, node.visibleItem, entry.key, entry.value);
      canvas.restore();
    }
  }

  /// 绘制滚动内容层，每个 item 会分别绘制蜡烛和启用的指标。
  @override
  void drawItem(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
    KLineVisibleItem<KLineModel> item,
  ) {
    final scrollOffset = context.controller.scrollOffset;
    canvas.save();
    canvas.clipRect(
      kLineDemoDrawableClipRect(
        _mainContentRect(context),
        scrollOffset: scrollOffset,
      ),
    );
    _drawCandle(canvas, context, item);
    _drawMainIndicators(canvas, context, item);
    canvas.restore();

    for (final entry in _secondaryRects(context).entries) {
      canvas.save();
      canvas.clipRect(
        kLineDemoDrawableClipRect(
          kLineDemoSecondaryContentRect(entry.value),
          scrollOffset: scrollOffset,
        ),
      );
      _drawSecondary(canvas, context, item, entry.key, entry.value);
      canvas.restore();
    }
  }

  /// 绘制固定覆盖层，目前用于长按十字线。
  @override
  void drawOverlay(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    _drawCrossLine(canvas, size, context);
  }

  /// 构建固定 overlay widget，例如指标标签和底部指标选择栏。
  @override
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
  ) {
    final selected =
        chartContext.selectedItem?.item ??
        (chartContext.visibleItems.isNotEmpty
            ? chartContext.visibleItems.first.item
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
  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
    KLineVisibleItem<KLineModel> selectedItem,
  ) {
    final candle = selectedItem.item;
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

  /// 按旧 Demo 样式绘制蜡烛实体与上下影线。
  void _drawCandle(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    KLineVisibleItem<KLineModel> item,
  ) {
    final range = _visiblePriceRange(context);
    final rect = _mainContentRect(context);
    final model = item.item;
    final centerX = _contentX(context, item.centerX);
    final bodyWidth = math.max(
      1,
      context.layout.scaledCandleWidth(context.controller.scale),
    );
    final highY = _valueToY(model.high, range, rect);
    final lowY = _valueToY(model.low, range, rect);
    final openY = _valueToY(model.open, range, rect);
    final closeY = _valueToY(model.close, range, rect);
    final color = model.close >= model.open
        ? context.theme.candleUpColor
        : context.theme.candleDownColor;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(centerX, highY),
      Offset(centerX, lowY),
      Paint()
        ..color = color
        ..strokeWidth = context.theme.candleStrokeWidth,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        centerX - bodyWidth / 2,
        math.min(openY, closeY),
        centerX + bodyWidth / 2,
        math.max(math.max(openY, closeY), math.min(openY, closeY) + 1),
      ),
      paint,
    );
  }

  /// 使用预计算好的 layout node 绘制蜡烛，避免绘制阶段重复计算坐标。
  void _drawCandleNode(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    _KLineDemoLayoutNode node,
  ) {
    final paint = Paint()
      ..color = node.candleColor
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(node.centerX, node.highY),
      Offset(node.centerX, node.lowY),
      Paint()
        ..color = node.candleColor
        ..strokeWidth = context.theme.candleStrokeWidth,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        node.centerX - node.bodyWidth / 2,
        math.min(node.openY, node.closeY),
        node.centerX + node.bodyWidth / 2,
        math.max(
          math.max(node.openY, node.closeY),
          math.min(node.openY, node.closeY) + 1,
        ),
      ),
      paint,
    );
  }

  /// 根据当前启用的主图指标绘制 MA/EMA/BOLL 线。
  void _drawMainIndicators(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    KLineVisibleItem<KLineModel> item,
  ) {
    final active = context.controller.activeIndicatorIds;
    if (active.contains(KLineTechnicalIndicatorType.ma.name)) {
      _drawIndicatorLine(canvas, context, item, _mainContentRect(context), [
        (_IndicatorValueExtractor.ma5, context.theme.indicatorColorAt(0)),
        (_IndicatorValueExtractor.ma10, context.theme.indicatorColorAt(1)),
        (_IndicatorValueExtractor.ma30, context.theme.indicatorColorAt(2)),
      ]);
    }
    if (active.contains(KLineTechnicalIndicatorType.ema.name)) {
      _drawIndicatorLine(canvas, context, item, _mainContentRect(context), [
        (_IndicatorValueExtractor.ema5, context.theme.indicatorColorAt(3)),
        (_IndicatorValueExtractor.ema10, context.theme.indicatorColorAt(4)),
        (_IndicatorValueExtractor.ema30, context.theme.indicatorColorAt(5)),
      ]);
    }
    if (active.contains(KLineTechnicalIndicatorType.boll.name)) {
      _drawIndicatorLine(canvas, context, item, _mainContentRect(context), [
        (_IndicatorValueExtractor.bollUpper, context.theme.indicatorColorAt(0)),
        (
          _IndicatorValueExtractor.bollMiddle,
          context.theme.indicatorColorAt(1),
        ),
        (_IndicatorValueExtractor.bollLower, context.theme.indicatorColorAt(2)),
      ]);
    }
  }

  /// 分发副图指标绘制，保证每类指标使用自己的数值范围。
  void _drawSecondary(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    KLineVisibleItem<KLineModel> item,
    KLineTechnicalIndicatorType type,
    Rect rect,
  ) {
    final contentRect = kLineDemoSecondaryContentRect(rect);
    switch (type) {
      case KLineTechnicalIndicatorType.volume:
        _drawVolume(canvas, context, item, contentRect);
      case KLineTechnicalIndicatorType.macd:
        _drawMacd(canvas, context, item, contentRect);
      case KLineTechnicalIndicatorType.kdj:
        _drawIndicatorLine(
          canvas,
          context,
          item,
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
        _drawIndicatorLine(
          canvas,
          context,
          item,
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
        _drawIndicatorLine(
          canvas,
          context,
          item,
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
  void _drawVolume(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    KLineVisibleItem<KLineModel> item,
    Rect rect,
  ) {
    final maxVolume = context.visibleItems.fold<double>(
      0,
      (value, item) => math.max(value, item.item.volume),
    );
    if (maxVolume <= 0) return;
    final height = (rect.height * (item.item.volume / maxVolume)).toDouble();
    final y = rect.bottom - height;
    final centerX = _contentX(context, item.centerX);
    final color = item.item.isRising
        ? context.theme.candleUpColor
        : context.theme.candleDownColor;
    final barWidth = math.max(
      1.0,
      context.layout.scaledCandleWidth(context.controller.scale),
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX - barWidth / 2, y, barWidth, height),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    _drawIndicatorLine(
      canvas,
      context,
      item,
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
  void _drawMacd(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    KLineVisibleItem<KLineModel> item,
    Rect rect,
  ) {
    final dataRange = _indicatorRange(context, [
      _IndicatorValueExtractor.macd,
      _IndicatorValueExtractor.dif,
      _IndicatorValueExtractor.dea,
    ]);
    final range = (math.min(0.0, dataRange.$1), math.max(0.0, dataRange.$2));
    final macd = item.item.kLineTechnicalIndicatorsModel?.macd;
    if (macd != null) {
      final zeroY = _valueToY(0, range, rect);
      final valueY = _valueToY(macd, range, rect);
      final color = macd >= 0
          ? context.theme.candleUpColor
          : context.theme.candleDownColor;
      final barWidth = math.max(
        1,
        context.layout.scaledCandleWidth(context.controller.scale) * 0.6,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          _contentX(context, item.centerX) - barWidth / 2,
          math.min(zeroY, valueY),
          _contentX(context, item.centerX) + barWidth / 2,
          math.max(zeroY, valueY),
        ),
        Paint()..color = color,
      );
    }
    _drawIndicatorLine(canvas, context, item, rect, [
      (_IndicatorValueExtractor.dif, context.theme.indicatorColorAt(1)),
      (_IndicatorValueExtractor.dea, context.theme.indicatorColorAt(3)),
    ], fixedRange: range);
  }

  /// 绘制相邻两个可见 K 线之间的指标线段。
  void _drawIndicatorLine(
    Canvas canvas,
    KLineChartContext<KLineModel> context,
    KLineVisibleItem<KLineModel> item,
    Rect rect,
    List<(_IndicatorValueExtractor, Color)> lines, {
    (double min, double max)? fixedRange,
  }) {
    KLineVisibleItem<KLineModel>? previous;
    for (final visibleItem in context.visibleItems) {
      if (visibleItem.index == item.index - 1) {
        previous = visibleItem;
        break;
      }
    }
    if (previous == null) return;

    for (final line in lines) {
      final current = line.$1.value(item.item.kLineTechnicalIndicatorsModel);
      final previousValue = line.$1.value(
        previous.item.kLineTechnicalIndicatorsModel,
      );
      if (current == null || previousValue == null) continue;
      final range = fixedRange ?? _visiblePriceRange(context);
      final paint = Paint()
        ..color = line.$2
        ..strokeWidth = context.theme.indicatorStrokeWidth;
      canvas.drawLine(
        Offset(
          _contentX(context, previous.centerX),
          _valueToY(previousValue, range, rect),
        ),
        Offset(
          _contentX(context, item.centerX),
          _valueToY(current, range, rect),
        ),
        paint,
      );
    }
  }

  /// 绘制长按选中时的十字线和交点圆点。
  void _drawCrossLine(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final selected = context.selectedItem;
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
  Rect _mainRect(KLineChartContext<KLineModel> context) {
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
  Rect _mainContentRect(KLineChartContext<KLineModel> context) {
    final main = _mainRect(context);
    return Rect.fromLTRB(
      main.left,
      main.top + _contentTopPadding,
      main.right,
      main.bottom - _contentBottomPadding,
    );
  }

  /// 当前启用的副图类型列表。
  List<KLineTechnicalIndicatorType> _activeSecondaryTypes(
    KLineChartContext<KLineModel> context,
  ) {
    return KLineTechnicalIndicatorType.secondTypes
        .where(
          (type) => context.controller.activeIndicatorIds.contains(type.name),
        )
        .toList();
  }

  /// 计算每个副图模块在固定网格层中的区域。
  Map<KLineTechnicalIndicatorType, Rect> _secondaryRects(
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
  List<String> _dateLabels(KLineChartContext<KLineModel> context) {
    if (context.visibleItems.isEmpty) return const [];
    final labels = <String>[];
    for (var i = 0; i < context.layout.gridVerticalCount; i++) {
      final index =
          (i *
                  (context.visibleItems.length - 1) /
                  (context.layout.gridVerticalCount - 1))
              .round();
      labels.add(context.visibleItems[index].item.dateString);
    }
    return labels;
  }

  /// Canvas 文本绘制工具，复用 TextPainter 降低临时对象创建。
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
  double _contentX(KLineChartContext<KLineModel> context, double x) {
    return x + context.layout.chartPadding.left;
  }

  /// 计算当前可见 K 线的价格范围。
  (double min, double max) _visiblePriceRange(
    KLineChartContext<KLineModel> context,
  ) {
    if (context.visibleItems.isEmpty) return (0, 1);
    var min = context.visibleItems.first.item.low;
    var max = context.visibleItems.first.item.high;
    for (final item in context.visibleItems) {
      min = math.min(min, item.item.low);
      max = math.max(max, item.item.high);
    }
    if (min == max) return (min - 1, max + 1);
    return (min, max);
  }

  /// 计算当前可见 K 线中指定指标的数值范围。
  (double min, double max) _indicatorRange(
    KLineChartContext<KLineModel> context,
    List<_IndicatorValueExtractor> extractors,
  ) {
    final values = <double>[];
    for (final item in context.visibleItems) {
      for (final extractor in extractors) {
        final value = extractor.value(item.item.kLineTechnicalIndicatorsModel);
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
  double _valueToY(double value, (double min, double max) range, Rect rect) {
    final ratio = (value - range.$1) / (range.$2 - range.$1);
    return rect.bottom - ratio * rect.height;
  }
}
