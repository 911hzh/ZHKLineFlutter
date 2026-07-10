import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_data_adapter.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_default_delegate.dart';

void main() {
  test('resolves available and active indicators by string id', () {
    const cci = KLineIndicatorSpec<_Candle>(
      id: 'cci',
      label: 'CCI',
      height: 88,
      series: [
        KLineIndicatorSeries<_Candle>(
          id: 'cci14',
          label: 'CCI14',
          colorIndex: 2,
          value: _cciValue,
        ),
      ],
    );
    const delegate = KLineDefaultDelegateImpl<_Candle>(
      adapter: _Adapter(),
      secondaryIndicators: [cci],
    );
    final context = _context(
      controller: KLineController(initialIndicators: const ['cci']),
    );
    const candle = _Candle(open: 10, high: 12, low: 9, close: 11, volume: 100);

    expect(delegate.availableSecondaryIndicators(context), const [cci]);
    expect(delegate.activeSecondaryIndicators(context), const [cci]);
    expect(
      delegate.chartHeight(context),
      100 + 88 + context.layout.indicatorSelectorHeight,
    );
    // 没有自定义 height 的副图指标必须回退到布局默认高度。
    expect(
      delegate.indicatorHeight(
        context,
        const KLineIndicatorSpec<_Candle>(id: 'vol', label: 'VOL'),
      ),
      context.layout.secondaryPaneHeight,
    );
    expect(
      delegate.adapter.secondaryIndicatorEntries(candle, cci).single.value,
      1,
    );
  });
}

KLineChartContext<_Candle> _context({
  KLineController? controller,
  List<KLineLayoutNode<_Candle>> layoutNodes = const [],
}) {
  return KLineChartContext<_Candle>(
    controller: controller ?? KLineController(),
    layout: const KLineLayoutConfig(mainChartHeight: 100),
    theme: const KLineTheme(),
    viewportSize: const Size(120, 180),
    itemCount: 1,
    itemExtent: 10,
    contentWidth: 10,
    visibleRange: const KLineVisibleRange(start: 0, end: 0),
    layoutNodes: layoutNodes,
  );
}

double? _cciValue(_Candle item) => item.close - item.open;

class _Candle {
  const _Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class _Adapter extends KLineDataAdapter<_Candle> {
  const _Adapter();

  @override
  double open(_Candle item) => item.open;

  @override
  double high(_Candle item) => item.high;

  @override
  double low(_Candle item) => item.low;

  @override
  double close(_Candle item) => item.close;

  @override
  double volume(_Candle item) => item.volume;

  @override
  String dateLabel(_Candle item) => 'T';

  @override
  double? indicatorValue(_Candle item, String valueId) {
    return switch (valueId) {
      KLineDefaultIndicators.volumeMA5 => item.volume,
      _ => null,
    };
  }
}
