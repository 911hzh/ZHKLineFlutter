import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

class _Candle {
  const _Candle(
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
    this.time,
  );

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime time;
}

class _Delegate extends KLineChartDelegate<_Candle> {
  @override
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<_Candle> chartContext,
  ) {
    return Text('items:${chartContext.layoutNodes.length}');
  }
}

void main() {
  testWidgets('KLineChart renders as package widget', (tester) async {
    final data = [
      _Candle(1, 3, 0.5, 2, 100, DateTime(2026)),
      _Candle(2, 4, 1, 3, 120, DateTime(2026, 1, 2)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 300,
          height: 240,
          child: KLineChart<_Candle>(dataSource: data, delegate: _Delegate()),
        ),
      ),
    );

    expect(find.text('items:2'), findsOneWidget);
  });
}
