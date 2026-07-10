import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';
import 'package:kline_flutter/src/kline/widgets/scale_gesture_handler.dart';

void main() {
  test('resolves item extent, content width, and clamped scroll offset', () {
    final handler = ScaleGestureHandler();
    final controller = KLineController(
      initialScale: 2,
      initialScrollOffset: 500,
    );
    const layout = KLineLayoutConfig(candleWidth: 8, candleSpacing: 2);

    final itemExtent = handler.resolveItemExtent(layout: layout, scale: 2);
    final contentWidth = handler.resolveContentWidth(
      layout: layout,
      itemCount: 3,
      itemExtent: itemExtent,
      viewportWidth: 100,
      scale: 2,
    );

    expect(itemExtent, 20);
    expect(contentWidth, 100);
    expect(
      handler.resolveScrollOffset(
        controller: controller,
        contentWidth: contentWidth,
        viewportWidth: 100,
      ),
      0,
    );
  });

  test('handleUpdate scales around the start focal point within bounds', () {
    final handler = ScaleGestureHandler();
    final controller = KLineController(
      initialScale: 1,
      initialScrollOffset: 20,
    );
    const layout = KLineLayoutConfig(candleWidth: 8, candleSpacing: 2);
    final context = KLineChartContext<String>(
      controller: controller,
      layout: layout,
      theme: const KLineTheme(),
      viewportSize: const Size(100, 100),
      itemCount: 20,
      itemExtent: 10,
      contentWidth: 200,
      visibleRange: const KLineVisibleRange(start: 0, end: 5),
      layoutNodes: const [],
    );

    handler.handleStart(
      controller: controller,
      details: ScaleStartDetails(localFocalPoint: const Offset(30, 0)),
    );
    handler.handleUpdate(
      controller: controller,
      layout: layout,
      context: context,
      details: ScaleUpdateDetails(scale: 2),
    );

    expect(controller.scale, 2);
    expect(controller.scrollOffset, 70);
  });

  test('resolveLayout clamps offset after scale changes', () {
    final handler = ScaleGestureHandler();
    final controller = KLineController(initialScrollOffset: 500);
    const layout = KLineLayoutConfig();

    handler.resolveLayout(
      controller: controller,
      layout: layout,
      itemCount: 100,
      viewportWidth: 100,
    );
    controller.setScale(0.5);
    final metrics = handler.resolveLayout(
      controller: controller,
      layout: layout,
      itemCount: 2,
      viewportWidth: 100,
    );

    expect(metrics.scrollOffset, 0);
  });
}
