import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

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

class _RecordingDataSource extends KLineChartDataSource<_ExternalCandle> {
  _RecordingDataSource(this.items);

  final List<_ExternalCandle> items;
  final requestedRanges = <KLineVisibleRange>[];

  @override
  int numberOfItems(KLineChartContext<_ExternalCandle> context) => items.length;

  @override
  _ExternalCandle itemAt(
    KLineChartContext<_ExternalCandle> context,
    int index,
  ) {
    return items[index];
  }

  @override
  void chartDidRequestData(
    KLineChartContext<_ExternalCandle> context,
    KLineDataRequest request,
  ) {
    requestedRanges.add(request.visibleRange);
  }
}

class _RecordingDelegate extends KLineChartDelegate<_ExternalCandle> {
  int drawGridCount = 0;
  int drawItemCount = 0;
  int drawOverlayCount = 0;
  int selectionCount = 0;
  int moveCount = 0;
  int scaleUpdateCount = 0;
  Size? gridSize;
  final drawnIndices = <int>[];
  KLineVisibleItem<_ExternalCandle>? selectedItem;
  KLineChartContext<_ExternalCandle>? lastContext;

  @override
  double itemExtent(KLineChartContext<_ExternalCandle> context) => 10;

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
  void drawItem(
    Canvas canvas,
    Size size,
    KLineChartContext<_ExternalCandle> context,
    KLineVisibleItem<_ExternalCandle> item,
  ) {
    drawItemCount += 1;
    drawnIndices.add(item.index);
  }

  @override
  void drawOverlay(
    Canvas canvas,
    Size size,
    KLineChartContext<_ExternalCandle> context,
  ) {
    drawOverlayCount += 1;
  }

  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<_ExternalCandle> chartContext,
    KLineVisibleItem<_ExternalCandle> selectedItem,
  ) {
    return Text('selected:${selectedItem.item.close}');
  }

  @override
  void didSelectItem(
    KLineChartContext<_ExternalCandle> context,
    KLineVisibleItem<_ExternalCandle> item,
  ) {
    selectionCount += 1;
    selectedItem = item;
  }

  @override
  void didMoveSelection(
    KLineChartContext<_ExternalCandle> context,
    KLineVisibleItem<_ExternalCandle> item,
  ) {
    moveCount += 1;
  }

  @override
  void didUpdateScale(
    KLineChartContext<_ExternalCandle> context,
    double scale,
  ) {
    scaleUpdateCount += 1;
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

  testWidgets(
    'chart delegates data, drawing, selection UI, and interaction callbacks',
    (tester) async {
      final dataSource = _RecordingDataSource(candles);
      final delegate = _RecordingDelegate();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 260,
              child: KLineChart<_ExternalCandle>(
                dataSource: dataSource,
                delegate: delegate,
              ),
            ),
          ),
        ),
      );

      expect(delegate.drawGridCount, greaterThan(0));
      expect(delegate.drawItemCount, 3);
      expect(delegate.drawOverlayCount, greaterThan(0));
      expect(delegate.gridSize?.width, 320);
      expect(delegate.lastContext?.visibleItems, hasLength(3));
      expect(
        dataSource.requestedRanges,
        contains(const KLineVisibleRange(start: 0, end: 2)),
      );

      await tester.longPressAt(const Offset(25, 80));
      await tester.pump();

      expect(delegate.selectionCount, 1);
      expect(delegate.selectedItem?.index, 2);
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
      final dataSource = _RecordingDataSource(candles);
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
                dataSource: dataSource,
                delegate: delegate,
              ),
            ),
          ),
        ),
      );

      expect(delegate.gridSize?.width, 120);
      expect(delegate.drawnIndices.first, 0);
      expect(delegate.drawnIndices.length, lessThan(candles.length));

      controller.selectIndex(0);
      await tester.pump();
      expect(controller.selectedIndex, isNotNull);

      delegate.drawnIndices.clear();
      await tester.dragFrom(const Offset(100, 120), const Offset(-80, 0));
      await tester.pumpAndSettle();

      expect(controller.scrollOffset, greaterThan(0));
      expect(controller.selectedIndex, isNull);
      expect(delegate.drawnIndices.first, greaterThan(0));
      expect(dataSource.requestedRanges.last.start, greaterThan(0));

      controller.setScale(2);
      await tester.pumpAndSettle();

      expect(controller.scale, 2);
      expect(delegate.scaleUpdateCount, greaterThan(0));
      expect(dataSource.requestedRanges.last, controller.visibleRange);

      controller.setScrollOffset(30);
      await tester.pumpAndSettle();

      final scrollableState = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      expect(scrollableState.position.pixels, 30);

      controller.setScaleAroundFocalPoint(
        scale: 2,
        baseScale: 1,
        localFocalX: 60,
        contentFocalX: 90,
      );
      await tester.pumpAndSettle();

      expect(controller.scale, 2);
      expect(scrollableState.position.pixels, 120);
    },
  );
}
