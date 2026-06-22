import 'dart:math' as math;

import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:k_line_flutter/k_line_flutter.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorsModel.dart';

const double kLineDemoSecondaryContentVerticalPadding = 8.0;

Rect kLineDemoSecondaryContentRect(Rect rect) {
  final inset = math.min(
    kLineDemoSecondaryContentVerticalPadding,
    rect.height / 2,
  );
  return Rect.fromLTRB(
    rect.left,
    rect.top + inset,
    rect.right,
    rect.bottom - inset,
  );
}

Rect kLineDemoDrawableClipRect(Rect rect, {required double scrollOffset}) {
  return rect.shift(Offset(scrollOffset, 0));
}

class KLineDemoPage extends StatefulWidget {
  const KLineDemoPage({super.key});

  @override
  State<KLineDemoPage> createState() => _KLineDemoPageState();
}

class _KLineDemoPageState extends State<KLineDemoPage> {
  final _controller = KLineController(initialIndicators: const ['volume']);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPeriod(BuildContext context, KLinePeriod period) {
    _controller
      ..clearSelection()
      ..setScrollOffset(0);
    context.read<KLineDemoCubit>().selectPeriod(period);
  }

  void _zoomFromButton() {
    final nextScale = _controller.scale >= 3 ? 0.6 : _controller.scale * 1.2;
    _controller.setScaleAroundFocalPoint(
      scale: nextScale,
      baseScale: _controller.scale,
      localFocalX: MediaQuery.sizeOf(context).width / 2,
      contentFocalX:
          _controller.scrollOffset + MediaQuery.sizeOf(context).width / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KLineDemoCubit(klineStore: getIt<KlineStore>())..start(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<KLineDemoCubit, KLineDemoState>(
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _TopBar(onClose: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: 10),
                    _PeriodSelector(
                      selectedPeriod: state.selectedPeriod,
                      onSelected: (period) => _selectPeriod(context, period),
                      onZoom: _zoomFromButton,
                    ),
                    const SizedBox(height: 10),
                    _buildChart(context, state),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, KLineDemoState state) {
    if (state.isLoading && state.data.isEmpty) {
      return const SizedBox(
        height: 412,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.data.isEmpty) {
      return SizedBox(
        height: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<KLineDemoCubit>().retry(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.data.isEmpty) {
      return const SizedBox(height: 240, child: Center(child: Text('暂无数据')));
    }

    return Stack(
      children: [
        KLineChart<KLineModel>(
          controller: _controller,
          dataSource: _KLineDemoDataSource(state.data),
          delegate: const _KLineDemoDelegate(),
          layout: const KLineLayoutConfig(
            candleWidth: 8.5,
            candleSpacing: 2,
            mainChartHeight: 342,
            secondaryPaneHeight: 70,
            indicatorSelectorHeight: 30,
            gridHorizontalCount: 5,
            gridVerticalCount: 6,
            minScale: 0.6,
            maxScale: 3,
          ),
        ),
        if (state.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (state.error != null)
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(color: Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  '刷新失败: ${state.error}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'K线图表',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '关闭',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onSelected,
    required this.onZoom,
  });

  final KLinePeriod selectedPeriod;
  final ValueChanged<KLinePeriod> onSelected;
  final VoidCallback onZoom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: KLinePeriod.values.map((period) {
                final selected = period == selectedPeriod;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(period),
                    child: Center(
                      child: Text(
                        _periodText(period),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '更多',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  () {},
                ),
                _controlButton(
                  Icon(Icons.settings, size: 20, color: Colors.grey[600]),
                  () {},
                ),
                _controlButton(
                  Icon(Icons.search, size: 20, color: Colors.grey[600]),
                  onZoom,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(Widget child, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
  }

  String _periodText(KLinePeriod period) {
    switch (period) {
      case KLinePeriod.min15:
        return '15分';
      case KLinePeriod.min60:
        return '1时';
      case KLinePeriod.hour4:
        return '4时';
      case KLinePeriod.day1:
        return '1日';
      case KLinePeriod.mon1:
        return '1周';
    }
  }
}

class _IndicatorSelector extends StatelessWidget {
  const _IndicatorSelector({required this.context});

  final KLineChartContext<KLineModel> context;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: this.context.controller,
      builder: (context, _) {
        return SizedBox(
          height: 30,
          child: ColoredBox(
            color: Colors.white,
            child: Row(
              children: [
                for (final type in KLineTechnicalIndicatorType.mainTypes)
                  Expanded(child: _button(type, _indicatorText(type))),
                Container(width: 1, height: 10, color: Colors.grey[400]),
                for (final type in KLineTechnicalIndicatorType.secondTypes)
                  Expanded(child: _button(type, _indicatorText(type))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _button(KLineTechnicalIndicatorType type, String title) {
    final selected = context.controller.activeIndicatorIds.contains(type.name);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.controller.toggleIndicator(type.name),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? Colors.black : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  String _indicatorText(KLineTechnicalIndicatorType type) {
    switch (type) {
      case KLineTechnicalIndicatorType.volume:
        return 'VOL';
      case KLineTechnicalIndicatorType.ma:
        return 'MA';
      case KLineTechnicalIndicatorType.ema:
        return 'EMA';
      case KLineTechnicalIndicatorType.boll:
        return 'BOLL';
      case KLineTechnicalIndicatorType.macd:
        return 'MACD';
      case KLineTechnicalIndicatorType.kdj:
        return 'KDJ';
      case KLineTechnicalIndicatorType.rsi:
        return 'RSI';
      case KLineTechnicalIndicatorType.wr:
        return 'WR';
    }
  }
}

class _KLineDemoDataSource extends KLineChartDataSource<KLineModel> {
  const _KLineDemoDataSource(this.items);

  final List<KLineModel> items;

  @override
  int numberOfItems(KLineChartContext<KLineModel> context) => items.length;

  @override
  KLineModel itemAt(KLineChartContext<KLineModel> context, int index) {
    return items[index];
  }
}

class _KLineDemoDelegate extends KLineChartDelegate<KLineModel> {
  const _KLineDemoDelegate();

  static const _contentTopPadding = 30.0;
  static const _contentBottomPadding = 30.0;

  @override
  double chartHeight(KLineChartContext<KLineModel> context) {
    return context.layout.mainChartHeight +
        _activeSecondaryTypes(context).length *
            context.layout.secondaryPaneHeight +
        context.layout.indicatorSelectorHeight;
  }

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

  @override
  void drawOverlay(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    _drawCrossLine(canvas, size, context);
  }

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

  Rect _mainContentRect(KLineChartContext<KLineModel> context) {
    final main = _mainRect(context);
    return Rect.fromLTRB(
      main.left,
      main.top + _contentTopPadding,
      main.right,
      main.bottom - _contentBottomPadding,
    );
  }

  List<KLineTechnicalIndicatorType> _activeSecondaryTypes(
    KLineChartContext<KLineModel> context,
  ) {
    return KLineTechnicalIndicatorType.secondTypes
        .where(
          (type) => context.controller.activeIndicatorIds.contains(type.name),
        )
        .toList();
  }

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

  double _contentX(KLineChartContext<KLineModel> context, double x) {
    return x + context.layout.chartPadding.left;
  }

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

  double _valueToY(double value, (double min, double max) range, Rect rect) {
    final ratio = (value - range.$1) / (range.$2 - range.$1);
    return rect.bottom - ratio * rect.height;
  }
}

class _MainIndicatorLabels extends StatelessWidget {
  const _MainIndicatorLabels({required this.context, required this.selected});

  final KLineChartContext<KLineModel> context;
  final KLineModel selected;

  @override
  Widget build(BuildContext context) {
    final indicators = selected.kLineTechnicalIndicatorsModel;
    if (indicators == null) return const SizedBox.shrink();
    final active = this.context.controller.activeIndicatorIds;
    return Positioned(
      left: 12,
      top: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.contains(KLineTechnicalIndicatorType.ma.name))
            _row([
              ('MA5', indicators.ma5, this.context.theme.indicatorColorAt(0)),
              ('MA10', indicators.ma10, this.context.theme.indicatorColorAt(1)),
              ('MA30', indicators.ma30, this.context.theme.indicatorColorAt(2)),
            ]),
          if (active.contains(KLineTechnicalIndicatorType.ema.name))
            _row([
              ('EMA5', indicators.ema5, this.context.theme.indicatorColorAt(3)),
              (
                'EMA10',
                indicators.ema10,
                this.context.theme.indicatorColorAt(4),
              ),
              (
                'EMA30',
                indicators.ema30,
                this.context.theme.indicatorColorAt(5),
              ),
            ]),
          if (active.contains(KLineTechnicalIndicatorType.boll.name))
            _row([
              (
                'UPPER',
                indicators.bollUpper,
                this.context.theme.indicatorColorAt(0),
              ),
              (
                'MB',
                indicators.bollMiddle,
                this.context.theme.indicatorColorAt(1),
              ),
              (
                'LOWER',
                indicators.bollLower,
                this.context.theme.indicatorColorAt(2),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _row(List<(String, double?, Color)> values) {
    final children = values
        .where((value) => value.$2 != null)
        .map(
          (value) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: Text(
              '${value.$1}:${value.$2!.toStringAsFixed(2)}',
              style: TextStyle(color: value.$3, fontSize: 9),
            ),
          ),
        )
        .toList();
    if (children.isEmpty) return const SizedBox.shrink();
    return Row(children: children);
  }
}

class _SecondaryIndicatorLabels extends StatelessWidget {
  const _SecondaryIndicatorLabels({
    required this.context,
    required this.selected,
  });

  final KLineChartContext<KLineModel> context;
  final KLineModel selected;

  @override
  Widget build(BuildContext context) {
    final indicators = selected.kLineTechnicalIndicatorsModel;
    if (indicators == null) return const SizedBox.shrink();
    final activeTypes = KLineTechnicalIndicatorType.secondTypes
        .where(
          (type) =>
              this.context.controller.activeIndicatorIds.contains(type.name),
        )
        .toList();
    return Stack(
      children: [
        for (var i = 0; i < activeTypes.length; i++)
          Positioned(
            left: 12,
            top:
                this.context.layout.mainChartHeight +
                this.context.layout.secondaryPaneHeight * i +
                5,
            child: _label(activeTypes[i], indicators),
          ),
      ],
    );
  }

  Widget _label(
    KLineTechnicalIndicatorType type,
    KLineTechnicalIndicatorsModel indicators,
  ) {
    switch (type) {
      case KLineTechnicalIndicatorType.volume:
        return _row('VOL:', [
          ('MA5', indicators.volumeMA5),
          ('MA10', indicators.volumeMA10),
        ]);
      case KLineTechnicalIndicatorType.macd:
        return _row('MACD:', [
          ('DIF', indicators.dif),
          ('DEA', indicators.dea),
          ('MACD', indicators.macd),
        ]);
      case KLineTechnicalIndicatorType.kdj:
        return _row('KDJ:', [
          ('K', indicators.k),
          ('D', indicators.d),
          ('J', indicators.j),
        ]);
      case KLineTechnicalIndicatorType.rsi:
        return _row('RSI:', [
          ('RSI6', indicators.rsi6),
          ('RSI12', indicators.rsi12),
          ('RSI24', indicators.rsi24),
        ]);
      case KLineTechnicalIndicatorType.wr:
        return _row('WR:', [
          ('WR6', indicators.wr6),
          ('WR10', indicators.wr10),
          ('WR14', indicators.wr14),
        ]);
      case KLineTechnicalIndicatorType.ma:
      case KLineTechnicalIndicatorType.ema:
      case KLineTechnicalIndicatorType.boll:
        return const SizedBox.shrink();
    }
  }

  Widget _row(String title, List<(String, double?)> values) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 8, color: Colors.blue)),
        for (final value in values)
          if (value.$2 != null)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                '${value.$1}:${value.$2!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 8, color: Colors.black54),
              ),
            ),
      ],
    );
  }
}

enum _IndicatorValueExtractor {
  ma5,
  ma10,
  ma30,
  ema5,
  ema10,
  ema30,
  bollUpper,
  bollMiddle,
  bollLower,
  macd,
  dif,
  dea,
  k,
  d,
  j,
  rsi6,
  rsi12,
  rsi24,
  wr6,
  wr10,
  wr14,
  volumeMA5,
  volumeMA10;

  double? value(KLineTechnicalIndicatorsModel? model) {
    if (model == null) return null;
    return switch (this) {
      ma5 => model.ma5,
      ma10 => model.ma10,
      ma30 => model.ma30,
      ema5 => model.ema5,
      ema10 => model.ema10,
      ema30 => model.ema30,
      bollUpper => model.bollUpper,
      bollMiddle => model.bollMiddle,
      bollLower => model.bollLower,
      macd => model.macd,
      dif => model.dif,
      dea => model.dea,
      k => model.k,
      d => model.d,
      j => model.j,
      rsi6 => model.rsi6,
      rsi12 => model.rsi12,
      rsi24 => model.rsi24,
      wr6 => model.wr6,
      wr10 => model.wr10,
      wr14 => model.wr14,
      volumeMA5 => model.volumeMA5,
      volumeMA10 => model.volumeMA10,
    };
  }
}
