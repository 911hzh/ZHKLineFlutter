import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_data_adapter.dart';
import 'package:kline_flutter/src/kline/widgets/kline_views.dart';

void main() {
  testWidgets('indicator selector toggles controller indicator ids', (
    tester,
  ) async {
    final controller = KLineController(
      initialIndicators: const [KLineDefaultIndicators.volumeId],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KLineDefaultIndicatorSelector<_Candle>(
          context: _context(controller: controller),
          mainIndicators: [KLineDefaultIndicators.ma<_Candle>()],
          secondaryIndicators: [KLineDefaultIndicators.volume<_Candle>()],
        ),
      ),
    );

    await tester.tap(find.text('MA'));
    await tester.pump();

    expect(controller.activeIndicatorIds, [
      KLineDefaultIndicators.volumeId,
      KLineDefaultIndicators.maId,
    ]);

    await tester.tap(find.text('VOL'));
    await tester.pump();

    expect(controller.activeIndicatorIds, [KLineDefaultIndicators.maId]);
  });
}

KLineChartContext<_Candle> _context({required KLineController controller}) {
  return KLineChartContext<_Candle>(
    controller: controller,
    layout: const KLineLayoutConfig(mainChartHeight: 100),
    theme: const KLineTheme(),
    viewportSize: const Size(120, 180),
    itemCount: 1,
    itemExtent: 10,
    contentWidth: 10,
    visibleRange: const KLineVisibleRange(start: 0, end: 0),
    layoutNodes: const [],
  );
}

class _Candle {}
