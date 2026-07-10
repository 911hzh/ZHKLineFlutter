import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';
import 'package:kline_flutter/src/kline/widgets/kline_chart.dart';

void main() {
  testWidgets('renders loading and empty states without delegate layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KLineChart<_Candle>(
          isLoading: true,
          loadingBuilder: (_) => const Text('loading'),
          dataSource: const [],
          delegate: _RecordingDelegate(),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: KLineChart<_Candle>(
          emptyBuilder: (_) => const Text('empty'),
          dataSource: const [],
          delegate: _RecordingDelegate(),
        ),
      ),
    );

    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('delegates drawing, visible range, selection, and overlay', (
    tester,
  ) async {
    final delegate = _RecordingDelegate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 260,
              child: KLineChart<_Candle>(
                dataSource: candles,
                delegate: delegate,
              ),
            ),
          ),
        ),
      ),
    );

    expect(delegate.drawGridCount, greaterThan(0));
    expect(delegate.drawMainChartCount, greaterThan(0));
    expect(delegate.drawSecondaryChartsCount, greaterThan(0));
    expect(delegate.gridSize?.width, 320);
    expect(delegate.lastContext?.layoutNodes, hasLength(3));
    expect(delegate.layoutNodesRequestCount, greaterThan(0));
    expect(delegate.drawnMainIndices, [0, 1, 2]);
    expect(
      delegate.lastContext?.visibleRange,
      const KLineVisibleRange(start: 0, end: 2),
    );
    expect(find.text('items:3'), findsOneWidget);

    final chartTopLeft = tester.getTopLeft(find.byType(KLineChart<_Candle>));
    await tester.longPressAt(chartTopLeft + const Offset(25, 80));
    await tester.pump();

    expect(delegate.selectionCount, 1);
    expect(delegate.selectedNode?.index, 2);
    expect(find.text('selected:11.0'), findsOneWidget);
  });

  testWidgets('keeps grid fixed and delegates only visible content while '
      'scrolling and scaling', (tester) async {
    final data = List.generate(80, _candleAt);
    final delegate = _RecordingDelegate();
    final controller = KLineController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 180,
              child: KLineChart<_Candle>(
                controller: controller,
                dataSource: data,
                delegate: delegate,
              ),
            ),
          ),
        ),
      ),
    );

    expect(delegate.gridSize?.width, 120);
    expect(delegate.drawnMainIndices.first, 0);
    expect(delegate.drawnMainIndices.length, lessThan(data.length));

    controller.selectIndex(0);
    await tester.pump();

    delegate.drawnMainIndices.clear();
    final chartTopLeft = tester.getTopLeft(find.byType(KLineChart<_Candle>));
    await tester.dragFrom(
      chartTopLeft + const Offset(100, 120),
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();

    expect(controller.scrollOffset, greaterThan(0));
    expect(delegate.scrollCount, greaterThan(0));
    expect(controller.selectedIndex, isNull);
    expect(delegate.drawnMainIndices.first, greaterThan(0));
    expect(controller.visibleRange?.start, greaterThan(0));

    controller.setScale(2);
    await tester.pumpAndSettle();

    expect(controller.scale, 2);
    expect(controller.visibleRange, isNotNull);
  });

  testWidgets('consumes controller scroll requests after layout', (
    tester,
  ) async {
    final data = List.generate(80, _candleAt);
    final controller = KLineController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 180,
              child: KLineChart<_Candle>(
                controller: controller,
                dataSource: data,
                delegate: _RecordingDelegate(),
                layout: const KLineLayoutConfig(
                  candleWidth: 8,
                  candleSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 外部控制器只发一次性命令，真正 offset 要等本帧布局完成后由 chart 消费。
    controller.scrollToIndex(
      20,
      alignment: KLineScrollAlignment.left,
      animated: false,
    );
    await tester.pumpAndSettle();

    expect(controller.scrollOffset, 200);
    expect(controller.scrollRequest?.index, isNull);

    controller.scrollToLatest(animated: false);
    await tester.pumpAndSettle();

    expect(controller.scrollOffset, 0);
    expect(controller.scrollRequest?.latest, isFalse);
  });

  testWidgets('switches to a replacement external controller', (tester) async {
    final first = KLineController();
    final second = KLineController(initialScale: 2);
    final delegate = _RecordingDelegate();

    Future<void> pump(KLineController controller) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 180,
                child: KLineChart<_Candle>(
                  controller: controller,
                  dataSource: candles,
                  delegate: delegate,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pump(first);
    await pump(second);

    first.setScale(3);
    second.setScale(1.5);
    await tester.pump();

    expect(delegate.lastContext?.controller, second);
    expect(delegate.lastContext?.controller.scale, 1.5);
  });
}

const candles = [
  _Candle(open: 10, high: 13, low: 9, close: 12, volume: 100),
  _Candle(open: 12, high: 15, low: 11, close: 14, volume: 120),
  _Candle(open: 14, high: 16, low: 10, close: 11, volume: 140),
];

_Candle _candleAt(int index) {
  return _Candle(
    open: index.toDouble(),
    high: index + 2,
    low: index - 1,
    close: index + 1,
    volume: 100,
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

class _RecordingDelegate extends KLineChartDelegate<_Candle> {
  int drawGridCount = 0;
  int drawMainChartCount = 0;
  int drawSecondaryChartsCount = 0;
  int selectionCount = 0;
  int scrollCount = 0;
  int layoutNodesRequestCount = 0;
  Size? gridSize;
  final drawnMainIndices = <int>[];
  KLineLayoutNode<_Candle>? selectedNode;
  KLineChartContext<_Candle>? lastContext;

  @override
  List<KLineLayoutNode<_Candle>> getLayoutNodes(
    KLineChartContext<_Candle> context,
    List<_Candle> dataSource,
  ) {
    layoutNodesRequestCount += 1;
    return super.getLayoutNodes(context, dataSource);
  }

  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<_Candle> context) {
    drawGridCount += 1;
    gridSize = size;
    lastContext = context;
  }

  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<_Candle> context,
  ) {
    drawMainChartCount += 1;
    drawnMainIndices.addAll(context.layoutNodes.map((node) => node.index));
  }

  @override
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<_Candle> context,
  ) {
    drawSecondaryChartsCount += 1;
  }

  @override
  void didSelectItem(
    KLineChartContext<_Candle> context,
    KLineLayoutNode<_Candle> node,
  ) {
    selectionCount += 1;
    selectedNode = node;
  }

  @override
  void didScroll(
    KLineChartContext<_Candle> context,
    KLineScrollMetrics metrics,
  ) {
    scrollCount += 1;
  }

  @override
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<_Candle> chartContext,
  ) {
    return Text('items:${chartContext.layoutNodes.length}');
  }

  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<_Candle> chartContext,
    KLineLayoutNode<_Candle> selectedNode,
  ) {
    return Text('selected:${selectedNode.item.close}');
  }
}
