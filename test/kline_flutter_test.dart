import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/kline_flutter.dart';

void main() {
  test('public exports are available from the package entrypoint', () {
    final controller = KLineController(
      initialIndicators: const [KLineDefaultIndicators.volumeId],
    );
    final klineWidget = KLineWidget<_Candle>(
      controller: controller,
      dataSource: const [],
      adapter: const _CandleAdapter(),
    );
    const deepChart = DeepChart<DeepDepthEntry>(
      bids: [],
      asks: [],
      adapter: DeepDepthEntryAdapter(),
    );
    final ma = KLineDefaultIndicators.ma<_Candle>();

    expect(klineWidget, isA<KLineWidget<_Candle>>());
    expect(deepChart, isA<DeepChart<DeepDepthEntry>>());
    expect(ma.id, KLineDefaultIndicators.maId);
    expect(const KLineTheme(), isA<KLineTheme>());
    expect(const DeepChartTheme(), isA<DeepChartTheme>());
    expect(controller.activeIndicatorIds, [KLineDefaultIndicators.volumeId]);
  });
}

class _Candle {
  const _Candle();
}

class _CandleAdapter extends KLineDataAdapter<_Candle> {
  const _CandleAdapter();

  @override
  double open(_Candle item) => 10;

  @override
  double high(_Candle item) => 12;

  @override
  double low(_Candle item) => 9;

  @override
  double close(_Candle item) => 11;

  @override
  double volume(_Candle item) => 100;

  @override
  String dateLabel(_Candle item) => '09:30';
}
