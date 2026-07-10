import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';

void main() {
  test('computeVisibleRange clamps to available data', () {
    expect(
      KLineChartLayoutUtils.computeVisibleRange(
        itemCount: 5,
        itemExtent: 10,
        viewportWidth: 25,
        scrollOffset: 100,
      ),
      const KLineVisibleRange(start: 4, end: 4),
    );
  });

  test('buildLayoutNodes maps visible items to content frames', () {
    final context = _context(
      visibleRange: const KLineVisibleRange(start: 1, end: 2),
    );

    final nodes = KLineChartLayoutUtils.buildLayoutNodes(
      context: context,
      dataSource: const ['a', 'b', 'c'],
      visibleRange: context.visibleRange,
    );

    expect(nodes.map((node) => node.index), [1, 2]);
    expect(nodes.first.item, 'b');
    expect(nodes.first.frame.left, 10);
    expect(nodes.first.frame.height, 100);
  });

  test('context exposes selected visible node only', () {
    final controller = KLineController()..selectIndex(1);
    final selected = KLineLayoutNode<String>(
      index: 1,
      item: 'b',
      frame: Rect.zero,
    );
    final context = _context(controller: controller, layoutNodes: [selected]);

    expect(context.selectedNode, selected);

    controller.selectIndex(2);

    expect(context.selectedNode, isNull);
  });
}

KLineChartContext<String> _context({
  KLineController? controller,
  KLineVisibleRange visibleRange = const KLineVisibleRange(start: 0, end: 0),
  List<KLineLayoutNode<String>> layoutNodes = const [],
}) {
  return KLineChartContext<String>(
    controller: controller ?? KLineController(),
    layout: const KLineLayoutConfig(mainChartHeight: 100),
    theme: const KLineTheme(),
    viewportSize: const Size(100, 100),
    itemCount: 1,
    itemExtent: 10,
    contentWidth: 10,
    visibleRange: visibleRange,
    layoutNodes: layoutNodes,
  );
}
