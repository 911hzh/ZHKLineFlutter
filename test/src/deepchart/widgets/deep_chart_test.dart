import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/deepchart/adapter/deep_chart_data_adapter.dart';
import 'package:kline_flutter/src/deepchart/delegate/deep_chart_delegate.dart';
import 'package:kline_flutter/src/deepchart/widgets/deep_chart.dart';

void main() {
  testWidgets('renders loading and empty builders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeepChart<_Level>(
          isLoading: true,
          loadingBuilder: (_) => const Text('loading'),
          bids: const [],
          asks: const [],
          adapter: const _Adapter(),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: DeepChart<_Level>(
          emptyBuilder: (_) => const Text('empty'),
          bids: const [],
          asks: const [],
          adapter: const _Adapter(),
        ),
      ),
    );

    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('passes generic adapter data into delegate nodes', (
    tester,
  ) async {
    final delegate = _RecordingDelegate();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          child: DeepChart<_Level>(
            bids: const [_Level(100, 2)],
            asks: const [_Level(101, 3)],
            adapter: const _Adapter(),
            delegate: delegate,
          ),
        ),
      ),
    );

    expect(delegate.lastContext?.nodes.bids.single.price, 100);
    expect(delegate.lastContext?.nodes.asks.single.cumulativeSize, 3);
  });

  testWidgets('default overlay displays bid and ask legends', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 200,
          child: DeepChart<_Level>(
            bids: const [_Level(100, 2)],
            asks: const [_Level(101, 3)],
            adapter: const _Adapter(),
          ),
        ),
      ),
    );

    expect(find.text('买盘'), findsOneWidget);
    expect(find.text('卖盘'), findsOneWidget);
  });
}

class _Level {
  const _Level(this.price, this.size);

  final double price;
  final double size;
}

class _Adapter extends DeepChartDataAdapter<_Level> {
  const _Adapter();

  @override
  double price(_Level item) => item.price;

  @override
  double size(_Level item) => item.size;
}

class _RecordingDelegate extends DeepChartDelegate<_Level> {
  DeepChartContext<_Level>? lastContext;

  @override
  void drawGrid(Canvas canvas, Size size, DeepChartContext<_Level> context) {
    lastContext = context;
  }

  @override
  void drawChart(Canvas canvas, Size size, DeepChartContext<_Level> context) {}

  @override
  Widget? buildOverlayView(
    BuildContext context,
    DeepChartContext<_Level> chartContext,
  ) {
    return const SizedBox.shrink();
  }
}
