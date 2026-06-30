import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/kline_flutter.dart';
import 'package:kline_flutter/src/kline/u_default_impl/kline_default_delegate_util.dart';

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
  void drawGrid(
    Canvas canvas,
    Size size,
    KLineChartContext<_ExternalCandle> context,
  ) {
    drawGridCount += 1;
    gridSize = size;
    lastContext = context;
  }

  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<_ExternalCandle> context,
  ) {
    drawMainChartCount += 1;
    drawnMainIndices.addAll(context.layoutNodes.map((node) => node.index));
  }

  @override
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<_ExternalCandle> context,
  ) {
    drawSecondaryChartsCount += 1;
    drawnSecondaryIndices.addAll(context.layoutNodes.map((node) => node.index));
  }

  @override
  void didSelectItem(
    KLineChartContext<_ExternalCandle> context,
    KLineLayoutNode<_ExternalCandle> node,
  ) {
    selectionCount += 1;
    selectedNode = node;
  }

  @override
  void didMoveSelection(
    KLineChartContext<_ExternalCandle> context,
    KLineLayoutNode<_ExternalCandle> node,
  ) {
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
  void didScroll(
    KLineChartContext<_ExternalCandle> context,
    KLineScrollMetrics metrics,
  ) {
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
  double? indicatorValue(
    _ExternalCandle item,
    KLineDefaultIndicatorValue value,
  ) {
    return switch (value) {
      KLineDefaultIndicatorValue.ma5 => item.close.toDouble(),
      KLineDefaultIndicatorValue.bollUpper => item.high.toDouble() + 10,
      KLineDefaultIndicatorValue.bollMiddle => item.close.toDouble(),
      KLineDefaultIndicatorValue.bollLower => item.low.toDouble() - 10,
      KLineDefaultIndicatorValue.volumeMA5 => item.volume.toDouble(),
      _ => null,
    };
  }

  @override
  List<KLineIndicatorEntry> mainIndicatorEntries(
    _ExternalCandle item,
    KLineDefaultIndicatorType type,
  ) {
    if (type == KLineDefaultIndicatorType.ma) {
      return [
        KLineIndicatorEntry(
          label: 'MA7',
          value: item.close.toDouble(),
          colorIndex: 0,
        ),
      ];
    }
    return super.mainIndicatorEntries(item, type);
  }
}

class _HighVolumeMaAdapter extends _ExternalCandleAdapter {
  const _HighVolumeMaAdapter();

  @override
  double? indicatorValue(
    _ExternalCandle item,
    KLineDefaultIndicatorValue value,
  ) {
    return switch (value) {
      KLineDefaultIndicatorValue.volumeMA5 => item.volume.toDouble() * 2,
      _ => super.indicatorValue(item, value),
    };
  }
}

void main() {
  const candles = [
    _ExternalCandle(
      open: 10,
      high: 13,
      low: 9,
      close: 12,
      volume: 100,
      time: 1000,
    ),
    _ExternalCandle(
      open: 12,
      high: 15,
      low: 11,
      close: 14,
      volume: 120,
      time: 2000,
    ),
    _ExternalCandle(
      open: 14,
      high: 16,
      low: 10,
      close: 11,
      volume: 140,
      time: 3000,
    ),
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

    controller.setScaleAroundFocalPoint(
      scale: 2,
      baseScale: 1,
      localFocalX: 60,
      contentFocalX: 90,
    );

    expect(controller.scale, 2);
    expect(controller.scrollOffset, 120);
  });

  test('controller exposes live viewport commands', () {
    final controller = KLineController(initialFollowLatest: true);

    expect(controller.isFollowingLatest, isTrue);

    controller.scrollToIndex(8, alignment: KLineScrollAlignment.center);

    expect(controller.isFollowingLatest, isFalse);
    expect(controller.scrollRequest?.latest, isFalse);
    expect(controller.scrollRequest?.index, 8);
    expect(controller.scrollRequest?.alignment, KLineScrollAlignment.center);
    expect(controller.scrollRequest?.animated, isTrue);

    controller.selectIndex(3);
    controller.revealSelected(
      alignment: KLineScrollAlignment.left,
      animated: false,
    );

    expect(controller.scrollRequest?.latest, isFalse);
    expect(controller.scrollRequest?.index, 3);
    expect(controller.scrollRequest?.alignment, KLineScrollAlignment.left);
    expect(controller.scrollRequest?.animated, isFalse);

    controller.scrollToLatest(animated: false);

    expect(controller.isFollowingLatest, isTrue);
    expect(controller.scrollRequest?.latest, isTrue);
    expect(controller.scrollRequest?.index, isNull);
    expect(controller.scrollRequest?.animated, isFalse);
  });

  testWidgets(
    'chart delegates data, drawing, selection UI, and interaction callbacks',
    (tester) async {
      final delegate = _RecordingDelegate();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 260,
              child: KLineChart<_ExternalCandle>(
                dataSource: candles,
                delegate: delegate,
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
      expect(delegate.drawnSecondaryIndices, [0, 1, 2]);
      expect(
        delegate.lastContext?.visibleRange,
        const KLineVisibleRange(start: 0, end: 2),
      );

      await tester.longPressAt(const Offset(25, 80));
      await tester.pump();

      expect(delegate.selectionCount, 1);
      expect(delegate.selectedNode?.index, 2);
      expect(
        delegate.lastContext?.controller.selectionLocalPosition,
        isNotNull,
      );
      expect(
        delegate.lastContext?.controller.selectionContentPosition,
        isNotNull,
      );
      expect(find.text('selected:11'), findsOneWidget);

      final gesture = await tester.startGesture(const Offset(5, 80));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(const Offset(15, 80));
      await tester.pump();
      await gesture.up();

      expect(delegate.moveCount, greaterThan(0));
    },
  );

  testWidgets(
    'chart keeps grid fixed and delegates only visible content while scrolling and scaling',
    (tester) async {
      final candles = List.generate(
        80,
        (index) => _ExternalCandle(
          open: index,
          high: index + 2,
          low: index - 1,
          close: index + 1,
          volume: 100,
          time: index,
        ),
      );
      final delegate = _RecordingDelegate();
      final controller = KLineController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 180,
              child: KLineChart<_ExternalCandle>(
                controller: controller,
                dataSource: candles,
                delegate: delegate,
              ),
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

      final scrollableState = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      expect(scrollableState.position.pixels, 30);
      final userScrollCount = delegate.scrollCount;

      controller.setScaleAroundFocalPoint(
        scale: 2,
        baseScale: 1,
        localFocalX: 60,
        contentFocalX: 90,
      );
      await tester.pumpAndSettle();

      expect(controller.scale, 2);
      expect(scrollableState.position.pixels, 120);
      expect(delegate.scrollCount, userScrollCount);
    },
  );

  testWidgets('chart reports ballistic scroll after user releases drag', (
    tester,
  ) async {
    final candles = List.generate(
      200,
      (index) => _ExternalCandle(
        open: index,
        high: index + 2,
        low: index - 1,
        close: index + 1,
        volume: 100,
        time: index,
      ),
    );
    final delegate = _RecordingDelegate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 180,
            child: KLineChart<_ExternalCandle>(
              dataSource: candles,
              delegate: delegate,
            ),
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

  testWidgets('default widget renders generic data through adapter', (
    tester,
  ) async {
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
              initialIndicators: const ['volume', 'ma', 'boll'],
              onScroll: (_, _) => scrollCount += 1,
            ),
          ),
        ),
      ),
    );

    expect(find.text('VOL'), findsWidgets);
    expect(find.text('MA'), findsOneWidget);
    expect(find.textContaining('MA7'), findsOneWidget);
    expect(find.textContaining('UB'), findsOneWidget);
    expect(find.textContaining('LB'), findsOneWidget);

    await tester.dragFrom(const Offset(280, 120), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(scrollCount, greaterThan(0));

    await tester.longPressAt(const Offset(40, 80));
    await tester.pump();
    expect(find.textContaining('Close'), findsOneWidget);
  });

  testWidgets(
    'default widget does not auto-adjust viewport after data update',
    (tester) async {
      final controller = KLineController();
      var data = [
        const _ExternalCandle(
          open: 12,
          high: 15,
          low: 11,
          close: 14,
          volume: 120,
          time: 2000,
        ),
        const _ExternalCandle(
          open: 14,
          high: 16,
          low: 10,
          close: 11,
          volume: 140,
          time: 3000,
        ),
      ];

      Future<void> pumpChart() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 120,
                height: 220,
                child: KLineWidget<_ExternalCandle>(
                  controller: controller,
                  dataSource: data,
                  adapter: const _ExternalCandleAdapter(),
                ),
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
        const _ExternalCandle(
          open: 10,
          high: 14,
          low: 9,
          close: 13,
          volume: 180,
          time: 1000,
        ),
        ...data,
      ];
      await pumpChart();
      await tester.pumpAndSettle();

      expect(controller.selectedIndex, 1);
      expect(controller.scrollOffset, 21);
    },
  );

  testWidgets('business can request a scroll after data update', (
    tester,
  ) async {
    final controller = KLineController();
    var data = [
      const _ExternalCandle(
        open: 12,
        high: 15,
        low: 11,
        close: 14,
        volume: 120,
        time: 2000,
      ),
      const _ExternalCandle(
        open: 14,
        high: 16,
        low: 10,
        close: 11,
        volume: 140,
        time: 3000,
      ),
    ];

    Future<void> pumpChart() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 220,
              child: KLineWidget<_ExternalCandle>(
                controller: controller,
                dataSource: data,
                adapter: const _ExternalCandleAdapter(),
              ),
            ),
          ),
        ),
      );
    }

    await pumpChart();
    data = [
      const _ExternalCandle(
        open: 10,
        high: 14,
        low: 9,
        close: 13,
        volume: 180,
        time: 1000,
      ),
      ...data,
    ];
    await pumpChart();
    controller.scrollToLatest();
    await tester.pumpAndSettle();

    expect(controller.scrollOffset, 0);

    data = [
      ...data,
      ...List.generate(
        12,
        (index) => _ExternalCandle(
          open: 13 + index,
          high: 15 + index,
          low: 12 + index,
          close: 14 + index,
          volume: 200 + index,
          time: 4000 + index,
        ),
      ),
    ];
    await pumpChart();
    controller.scrollToIndex(
      data.length - 1,
      alignment: KLineScrollAlignment.right,
    );
    await tester.pumpAndSettle();

    expect(controller.scrollOffset, greaterThan(0));
    final scrollableState = tester.state<ScrollableState>(
      find.byType(Scrollable),
    );
    expect(
      scrollableState.position.pixels,
      closeTo(scrollableState.position.maxScrollExtent, 0.1),
    );
  });

  testWidgets(
    'default implementation util is reusable without delegate subclassing',
    (tester) async {
      KLineChartContext<_ExternalCandle>? capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 260,
              child: KLineChart<_ExternalCandle>(
                dataSource: candles,
                delegate: _CaptureContextDelegate(
                  onContext: (context) => capturedContext = context,
                ),
              ),
            ),
          ),
        ),
      );

      final context = capturedContext;
      expect(context, isNotNull);
      const adapter = _ExternalCandleAdapter();
      final nodes = KLineDefaultDelegateImplUtil.getLayoutNodes(
        context!,
        candles,
        adapter: adapter,
      );

      expect(
        KLineDefaultDelegateImplUtil.chartHeight(context),
        context.layout.mainChartHeight + context.layout.indicatorSelectorHeight,
      );
      expect(nodes, hasLength(candles.length));
      expect(nodes.first, isA<KLineDefaultLayoutNode<_ExternalCandle>>());
    },
  );

  testWidgets('default selection detail uses translucent gray aligned rows', (
    tester,
  ) async {
    const candle = _ExternalCandle(
      open: 9,
      high: 12,
      low: 8,
      close: 11,
      volume: 100,
      time: 1,
    );
    final context = KLineChartContext<_ExternalCandle>(
      controller: KLineController(),
      layout: const KLineLayoutConfig(),
      theme: const KLineTheme(),
      viewportSize: const Size(120, 180),
      itemCount: 1,
      itemExtent: 10,
      contentWidth: 10,
      visibleRange: const KLineVisibleRange(start: 0, end: 0),
      layoutNodes: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            final selectionView =
                KLineDefaultDelegateImplUtil.buildSelectionView(
                  buildContext,
                  context,
                  const KLineLayoutNode(
                    index: 0,
                    item: candle,
                    frame: Rect.fromLTWH(0, 0, 10, 180),
                  ),
                  adapter: const _ExternalCandleAdapter(),
                );
            return Stack(children: [selectionView!]);
          },
        ),
      ),
    );

    expect(find.text('Close'), findsOneWidget);
    expect(find.text('11.00'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox) return false;
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) return false;
        final color = decoration.color;
        return color != null && color != Colors.white && color.a < 1;
      }),
      findsOneWidget,
    );
  });

  test('default layout nodes respect main chart content padding', () {
    const layout = KLineLayoutConfig(
      mainChartHeight: 100,
      contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 40),
    );
    final context = KLineChartContext<_ExternalCandle>(
      controller: KLineController(),
      layout: layout,
      theme: const KLineTheme(),
      viewportSize: const Size(120, 100),
      itemCount: 1,
      itemExtent: 10,
      contentWidth: 10,
      visibleRange: const KLineVisibleRange(start: 0, end: 0),
      layoutNodes: const [],
    );
    const candle = _ExternalCandle(
      open: 5,
      high: 10,
      low: 0,
      close: 5,
      volume: 100,
      time: 1,
    );

    final nodes = KLineDefaultDelegateImplUtil.getLayoutNodes(context, [
      candle,
    ], adapter: const _ExternalCandleAdapter());
    final node = nodes.single as KLineDefaultLayoutNode<_ExternalCandle>;

    expect(node.highY, layout.contentPadding.top);
    expect(node.lowY, layout.mainChartHeight - layout.contentPadding.bottom);
  });

  test('default layout range includes active BOLL values', () {
    const layout = KLineLayoutConfig(
      mainChartHeight: 100,
      contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 10),
    );
    final controller = KLineController(
      initialIndicators: [KLineDefaultIndicatorType.boll.name],
    );
    final context = KLineChartContext<_ExternalCandle>(
      controller: controller,
      layout: layout,
      theme: const KLineTheme(),
      viewportSize: const Size(120, 100),
      itemCount: 1,
      itemExtent: 10,
      contentWidth: 10,
      visibleRange: const KLineVisibleRange(start: 0, end: 0),
      layoutNodes: const [],
    );
    const candle = _ExternalCandle(
      open: 5,
      high: 10,
      low: 0,
      close: 5,
      volume: 100,
      time: 1,
    );

    final nodes = KLineDefaultDelegateImplUtil.getLayoutNodes(context, [
      candle,
    ], adapter: const _ExternalCandleAdapter());
    final node = nodes.single as KLineDefaultLayoutNode<_ExternalCandle>;

    expect(node.highY, greaterThan(layout.contentPadding.top));
    expect(
      node.lowY,
      lessThan(layout.mainChartHeight - layout.contentPadding.bottom),
    );
  });

  test('default volume range includes volume moving averages', () {
    const candle = _ExternalCandle(
      open: 10,
      high: 12,
      low: 9,
      close: 11,
      volume: 100,
      time: 1,
    );
    final context = KLineChartContext<_ExternalCandle>(
      controller: KLineController(),
      layout: const KLineLayoutConfig(),
      theme: const KLineTheme(),
      viewportSize: const Size(120, 180),
      itemCount: 1,
      itemExtent: 10,
      contentWidth: 10,
      visibleRange: const KLineVisibleRange(start: 0, end: 0),
      layoutNodes: const [
        KLineLayoutNode(
          index: 0,
          item: candle,
          frame: Rect.fromLTWH(0, 0, 10, 180),
        ),
      ],
    );

    final range = KLineDefaultDelegateImplUtil.secondaryIndicatorRange(
      context,
      KLineDefaultIndicatorType.volume,
      adapter: const _HighVolumeMaAdapter(),
    );

    expect(range, (0, 200));
  });

  test('default cross line uses selected node content x in content layer', () {
    const candle = _ExternalCandle(
      open: 10,
      high: 12,
      low: 9,
      close: 11,
      volume: 100,
      time: 1,
    );
    final controller =
        KLineController()
          ..setScrollOffset(100)
          ..selectIndex(
            0,
            localPosition: const Offset(50, 60),
            contentPosition: const Offset(120, 60),
          );
    final context = KLineChartContext<_ExternalCandle>(
      controller: controller,
      layout: const KLineLayoutConfig(chartPadding: EdgeInsets.zero),
      theme: const KLineTheme(),
      viewportSize: const Size(200, 100),
      itemCount: 1,
      itemExtent: 10,
      contentWidth: 300,
      visibleRange: const KLineVisibleRange(start: 0, end: 0),
      layoutNodes: const [
        KLineDefaultLayoutNode(
          index: 0,
          item: candle,
          frame: Rect.fromLTWH(145, 0, 10, 100),
          centerX: 150,
          bodyWidth: 8,
          highY: 20,
          lowY: 80,
          openY: 40,
          closeY: 60,
          candleColor: Colors.red,
        ),
      ],
    );

    expect(KLineDefaultDelegateImplUtil.crossLineContentX(context), 150);
  });
}

class _CaptureContextDelegate extends KLineChartDelegate<_ExternalCandle> {
  const _CaptureContextDelegate({required this.onContext});

  final ValueChanged<KLineChartContext<_ExternalCandle>> onContext;

  @override
  void drawGrid(
    Canvas canvas,
    Size size,
    KLineChartContext<_ExternalCandle> context,
  ) {
    onContext(context);
  }
}
