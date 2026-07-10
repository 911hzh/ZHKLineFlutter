import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';

void main() {
  test('exposes chart state changes to package consumers', () {
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

  test('exposes live viewport commands', () {
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

    final revision = controller.scrollRequest!.revision;
    controller.consumeScrollRequest(revision);

    expect(controller.scrollRequest?.index, isNull);

    controller.scrollToLatest(animated: false);

    expect(controller.isFollowingLatest, isTrue);
    expect(controller.scrollRequest?.latest, isTrue);
    expect(controller.scrollRequest?.index, isNull);
    expect(controller.scrollRequest?.animated, isFalse);
  });

  test('selection positions clear when selection clears', () {
    final controller = KLineController();

    controller.selectIndex(
      1,
      localPosition: const Offset(10, 20),
      contentPosition: const Offset(30, 20),
    );
    controller.clearSelection();

    expect(controller.selectedIndex, isNull);
    expect(controller.selectionLocalPosition, isNull);
    expect(controller.selectionContentPosition, isNull);
  });

  test('active indicators toggle by id', () {
    final controller = KLineController(initialIndicators: const ['volume']);

    controller
      ..toggleIndicator('ma')
      ..toggleIndicator('volume');

    expect(controller.activeIndicatorIds, ['ma']);

    controller.setActiveIndicators(const ['boll']);

    expect(controller.activeIndicatorIds, ['boll']);
  });
}
