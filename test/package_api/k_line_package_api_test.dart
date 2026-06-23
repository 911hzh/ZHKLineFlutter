import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/k_line_flutter.dart';
import 'package:k_line_flutter/src/kline/u_default_impl/kline_default_delegate_util.dart';

class _ExternalCandle {
  const _ExternalCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.time,
  });

  final num open;
  final num high;
  final num low;
  final num close;
  final num volume;
  final int time;
}

class _RecordingDelegate extends KLineChartDelegate<_ExternalCandle> {
  int drawGridCount = 0;
  int drawMainChartCount = 0;
  int drawSecondaryChartsCount = 0;
  int selectionCount = 0;
  int moveCount = 0;
  int scrollCount = 0;
  int layoutNodesRequestCount = 0;
  Size? gridSize;
  final drawnMainIndices = <int>[];
  final drawnSecondaryIndices = <int>[];
  KLineLayoutNode<_ExternalCandle>? selectedNode;
  KLineChartContext<_ExternalCandle>? lastContext;
  KLineScrollMetrics? lastScrollMetrics;

  @override
  List<KLineLayoutNode<_ExternalCandle>> getLayoutNodes(
    KLineChartContext<_ExternalCandle> context,
    List<_ExternalCandle> dataSource,
  ) {
    layoutNodesRequestCount += 1;
    return super.getLayoutNodes(context, dataSource);
  }

  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<_ExternalCandle> context) {
    drawGridCount += 1;
    gridSize = size;
    lastContext = context;
  }

  @override
  void drawMainChart(Canvas canvas, Size size, KLineChartContext<_ExternalCandle> context) {
    drawMainChartCount += 1;
    drawnMainIndices.addAll(context.layoutNodes.map((node) => node.index));
  }

  @override
  void drawSecondaryCharts(Canvas canvas, Size size, KLineChartContext<_ExternalCandle> context) {
    drawSecondaryChartsCount += 1;
    drawnSecondaryIndices.addAll(context.layoutNodes.map((node) => node.index));
  }

  @override
  void didSelectItem(KLineChartContext<_ExternalCandle> context, KLineLayoutNode<_ExternalCandle> node) {
    selectionCount += 1;
    selectedNode = node;
  }

  @override
  void didMoveSelection(KLineChartContext<_ExternalCandle> context, KLineLayoutNode<_ExternalCandle> node) {
    moveCount += 1;
  }

  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<_ExternalCandle> chartContext,
    KLineLayoutNode<_ExternalCandle> selectedNode,
  ) {
    return Text('selected:${selectedNode.item.close}');
  }

  @override
  void didScroll(KLineChartContext<_ExternalCandle> context, KLineScrollMetrics metrics) {
    scrollCount += 1;
    lastScrollMetrics = metrics;
  }
}

class _ExternalCandleAdapter extends KLineDataAdapter<_ExternalCandle> {
  const _ExternalCandleAdapter();

  @override
  double open(_ExternalCandle item) => item.open.toDouble();

  @override
  double high(_ExternalCandle item) => item.high.toDouble();

  @override
  double low(_ExternalCandle item) => item.low.toDouble();

  @override
  double close(_ExternalCandle item) => item.close.toDouble();

  @override
  double volume(_ExternalCandle item) => item.volume.toDouble();

  @override
  String dateLabel(_ExternalCandle item) => 'T${item.time}';

  @override
  double? indicatorValue(_ExternalCandle item, KLineDefaultIndicatorValue value) {
    return switch (value) {
      KLineDefaultIndicatorValue.ma5 => item.close.toDouble(),
      KLineDefaultIndicatorValue.volumeMA5 => item.volume.toDouble(),
      _ => null,
    };
  }

  @override
  List<KLineIndicatorEntry> mainIndicatorEntries(_ExternalCandle item, KLineDefaultIndicatorType type) {
    if (type == KLineDefaultIndicatorType.ma) {
      return [KLineIndicatorEntry(label: 'MA7', value: item.close.toDouble(), colorIndex: 0)];
    }
    return super.mainIndicatorEntries(item, type);
  }
}

void main() {
  const candles = [
    _ExternalCandle(open: 10, high: 13, low: 9, close: 12, volume: 100, time: 1000),
    _ExternalCandle(open: 12, high: 15, low: 11, close: 14, volume: 120, time: 2000),
    _ExternalCandle(open: 14, high: 16, low: 10, close: 11, volume: 140, time: 3000),
  ];

  test('controller exposes chart state changes to package consumers', () {
    final controller = KLineController(initialScale: 1.2);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    controller
      ..setScale(2)
      ..setScrollOffset(18)
      ..selectIndex(1)
      ..setVisibleRange(const KLineVisibleRange(start: 0, end: 2));

    expect(controller.scale, 2);
    expect(controller.scrollOffset, 18);
    expect(controller.selectedIndex, 1);
    expect(controller.visibleRange, const KLineVisibleRange(start: 0, end: 2));
    expect(notifications, 4);

    controller.setScaleAroundFocalPoint(scale: 2, baseScale: 1, localFocalX: 60, contentFocalX: 90);

    expect(controller.scale, 2);
    expect(controller.scrollOffset, 120);
  });

  testWidgets('chart delegates data, drawing, selection UI, and interaction callbacks', (tester) async {
    final delegate = _RecordingDelegate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 260,
            child: KLineChart<_ExternalCandle>(dataSource: candles, delegate: delegate),
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
    expect(delegate.drawnSecondaryIndices, [0, 1, 2]);
    expect(delegate.lastContext?.visibleRange, const KLineVisibleRange(start: 0, end: 2));

    await tester.longPressAt(const Offset(25, 80));
    await tester.pump();

    expect(delegate.selectionCount, 1);
    expect(delegate.selectedNode?.index, 2);
    expect(delegate.lastContext?.controller.selectionLocalPosition, isNotNull);
    expect(delegate.lastContext?.controller.selectionContentPosition, isNotNull);
    expect(find.text('selected:11'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(5, 80));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(const Offset(15, 80));
    await tester.pump();
    await gesture.up();

    expect(delegate.moveCount, greaterThan(0));
  });

  testWidgets('chart keeps grid fixed and delegates only visible content while scrolling and scaling', (tester) async {
    final candles = List.generate(
      80,
      (index) =>
          _ExternalCandle(open: index, high: index + 2, low: index - 1, close: index + 1, volume: 100, time: index),
    );
    final delegate = _RecordingDelegate();
    final controller = KLineController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 180,
            child: KLineChart<_ExternalCandle>(controller: controller, dataSource: candles, delegate: delegate),
          ),
        ),
      ),
    );

    expect(delegate.gridSize?.width, 120);
    expect(delegate.drawnMainIndices.first, 0);
    expect(delegate.drawnSecondaryIndices.first, 0);
    expect(delegate.drawnMainIndices.length, lessThan(candles.length));

    controller.selectIndex(0);
    await tester.pump();
    expect(controller.selectedIndex, isNotNull);

    delegate.drawnMainIndices.clear();
    delegate.drawnSecondaryIndices.clear();
    await tester.dragFrom(const Offset(100, 120), const Offset(-80, 0));
    await tester.pumpAndSettle();

    expect(controller.scrollOffset, greaterThan(0));
    expect(delegate.scrollCount, greaterThan(0));
    expect(delegate.lastScrollMetrics?.pixels, controller.scrollOffset);
    expect(delegate.lastScrollMetrics?.maxScrollExtent, greaterThan(0));
    expect(controller.selectedIndex, isNull);
    expect(delegate.drawnMainIndices.first, greaterThan(0));
    expect(delegate.drawnSecondaryIndices.first, greaterThan(0));
    expect(controller.visibleRange?.start, greaterThan(0));

    controller.setScale(2);
    await tester.pumpAndSettle();

    expect(controller.scale, 2);
    expect(controller.visibleRange, isNotNull);

    controller.setScrollOffset(30);
    await tester.pumpAndSettle();

    final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollableState.position.pixels, 30);
    final userScrollCount = delegate.scrollCount;

    controller.setScaleAroundFocalPoint(scale: 2, baseScale: 1, localFocalX: 60, contentFocalX: 90);
    await tester.pumpAndSettle();

    expect(controller.scale, 2);
    expect(scrollableState.position.pixels, 120);
    expect(delegate.scrollCount, userScrollCount);
  });

  testWidgets('chart reports ballistic scroll after user releases drag', (tester) async {
    final candles = List.generate(
      200,
      (index) =>
          _ExternalCandle(open: index, high: index + 2, low: index - 1, close: index + 1, volume: 100, time: index),
    );
    final delegate = _RecordingDelegate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 180,
            child: KLineChart<_ExternalCandle>(dataSource: candles, delegate: delegate),
          ),
        ),
      ),
    );

    await tester.flingFrom(const Offset(100, 120), const Offset(-600, 0), 2500);
    await tester.pump();
    final dragScrollCount = delegate.scrollCount;

    await tester.pump(const Duration(milliseconds: 120));

    expect(dragScrollCount, greaterThan(0));
    expect(delegate.scrollCount, greaterThan(dragScrollCount));
  });

  testWidgets('default widget renders generic data through adapter', (tester) async {
    final candles = List.generate(
      80,
      (index) => _ExternalCandle(
        open: index + 10,
        high: index + 13,
        low: index + 9,
        close: index + 11,
        volume: 100 + index,
        time: index,
      ),
    );
    var scrollCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 260,
            child: KLineWidget<_ExternalCandle>(
              dataSource: candles,
              adapter: const _ExternalCandleAdapter(),
              initialIndicators: const ['volume', 'ma'],
              onScroll: (_, _) => scrollCount += 1,
            ),
          ),
        ),
      ),
    );

    expect(find.text('VOL'), findsWidgets);
    expect(find.text('MA'), findsOneWidget);
    expect(find.textContaining('MA7'), findsOneWidget);

    await tester.dragFrom(const Offset(280, 120), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(scrollCount, greaterThan(0));

    await tester.longPressAt(const Offset(40, 80));
    await tester.pump();
    expect(find.textContaining('Close'), findsOneWidget);
  });

  testWidgets('default implementation util is reusable without delegate subclassing', (tester) async {
    KLineChartContext<_ExternalCandle>? capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 260,
            child: KLineChart<_ExternalCandle>(
              dataSource: candles,
              delegate: _CaptureContextDelegate(onContext: (context) => capturedContext = context),
            ),
          ),
        ),
      ),
    );

    final context = capturedContext;
    expect(context, isNotNull);
    final adapter = const _ExternalCandleAdapter();
    final util = KLineDefaultDelegateImplUtil<_ExternalCandle>(adapter: adapter);
    final nodes = util.getLayoutNodes(context!, candles);

    expect(util.chartHeight(context), context.layout.mainChartHeight + context.layout.indicatorSelectorHeight);
    expect(nodes, hasLength(candles.length));
    expect(nodes.first, isA<KLineDefaultLayoutNode<_ExternalCandle>>());
  });
}

class _CaptureContextDelegate extends KLineChartDelegate<_ExternalCandle> {
  const _CaptureContextDelegate({required this.onContext});

  final ValueChanged<KLineChartContext<_ExternalCandle>> onContext;

  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<_ExternalCandle> context) {
    onContext(context);
  }
}
