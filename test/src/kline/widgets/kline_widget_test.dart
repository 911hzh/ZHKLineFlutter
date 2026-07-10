import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_data_adapter.dart';
import 'package:kline_flutter/src/kline/widgets/kline_widget.dart';

void main() {
  testWidgets('renders loading, empty, and error placeholders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KLineWidget<_Candle>(
          isLoading: true,
          loadingBuilder: (_) => const Text('loading'),
          dataSource: const [],
          adapter: const _Adapter(),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: KLineWidget<_Candle>(
          emptyBuilder: (_) => const Text('empty'),
          dataSource: const [],
          adapter: const _Adapter(),
        ),
      ),
    );

    expect(find.text('empty'), findsOneWidget);

    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: KLineWidget<_Candle>(
          error: 'boom',
          onRetry: () => retries += 1,
          dataSource: const [],
          adapter: const _Adapter(),
        ),
      ),
    );

    expect(find.text('加载失败: boom'), findsOneWidget);
    await tester.tap(find.text('重试'));
    expect(retries, 1);
  });

  testWidgets('renders generic data through the default adapter path', (
    tester,
  ) async {
    var scrollCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 260,
          child: KLineWidget<_Candle>(
            dataSource: List.generate(80, _candleAt),
            adapter: const _Adapter(),
            initialIndicators: const ['volume', 'ma', 'boll'],
            onScroll: (_, _) => scrollCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('VOL'), findsWidgets);
    expect(find.text('MA'), findsOneWidget);
    expect(find.textContaining('MA7'), findsOneWidget);
    expect(find.textContaining('UB'), findsOneWidget);

    await tester.dragFrom(const Offset(280, 120), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(scrollCount, greaterThan(0));

    await tester.longPressAt(const Offset(40, 80));
    await tester.pump();

    expect(find.textContaining('Close'), findsOneWidget);
  });

  testWidgets('placeholder height comes from delegate', (tester) async {
    const placeholderKey = Key('placeholder');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: KLineWidget<_Candle>(
              dataSource: const [],
              adapter: const _Adapter(),
              delegate: const _FixedHeightDelegate(123),
              emptyBuilder: (_) => const SizedBox.expand(key: placeholderKey),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(placeholderKey)).height, 123);
  });

  testWidgets('shows top progress and error overlay with cached data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 260,
          child: KLineWidget<_Candle>(
            isLoading: true,
            error: 'stale',
            dataSource: const [
              _Candle(open: 10, high: 12, low: 9, close: 11, volume: 100),
            ],
            adapter: const _Adapter(),
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('刷新失败: stale'), findsOneWidget);
  });

  testWidgets('does not auto-adjust viewport after data update', (
    tester,
  ) async {
    final controller = KLineController();
    var data = [
      const _Candle(open: 12, high: 15, low: 11, close: 14, volume: 120),
      const _Candle(open: 14, high: 16, low: 10, close: 11, volume: 140),
    ];

    Future<void> pumpChart() async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 120,
            height: 220,
            child: KLineWidget<_Candle>(
              controller: controller,
              dataSource: data,
              adapter: const _Adapter(),
            ),
          ),
        ),
      );
    }

    await pumpChart();
    controller
      ..setScrollOffset(21)
      ..selectIndex(1);
    await tester.pumpAndSettle();

    data = [
      const _Candle(open: 10, high: 14, low: 9, close: 13, volume: 180),
      ...data,
    ];
    await pumpChart();
    await tester.pumpAndSettle();

    expect(controller.selectedIndex, 1);
    expect(controller.scrollOffset, 21);
  });
}

_Candle _candleAt(int index) {
  return _Candle(
    open: index + 10,
    high: index + 13,
    low: index + 9,
    close: index + 11,
    volume: (100 + index).toDouble(),
  );
}

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
      KLineDefaultIndicators.ma5 => item.close,
      KLineDefaultIndicators.bollUpper => item.high + 10,
      KLineDefaultIndicators.bollMiddle => item.close,
      KLineDefaultIndicators.bollLower => item.low - 10,
      KLineDefaultIndicators.volumeMA5 => item.volume,
      _ => null,
    };
  }

  @override
  List<KLineIndicatorEntry> mainIndicatorEntries(
    _Candle item,
    KLineIndicatorSpec<_Candle> indicator,
  ) {
    if (indicator.id == KLineDefaultIndicators.maId) {
      return [
        KLineIndicatorEntry(label: 'MA7', value: item.close, colorIndex: 0),
      ];
    }
    return super.mainIndicatorEntries(item, indicator);
  }
}

class _FixedHeightDelegate extends KLineChartDelegate<_Candle> {
  const _FixedHeightDelegate(this.height);

  final double height;

  @override
  double chartHeight(KLineChartContext<_Candle> context) => height;
}
