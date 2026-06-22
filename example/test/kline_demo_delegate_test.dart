import 'package:example/module/usecase/pages/kline/KLineDemoPage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('secondary indicator content rect reserves top and bottom padding', () {
    const rect = Rect.fromLTWH(2, 342, 316, 70);

    final contentRect = kLineDemoSecondaryContentRect(rect);

    expect(contentRect.left, rect.left);
    expect(contentRect.right, rect.right);
    expect(contentRect.top, greaterThan(rect.top));
    expect(contentRect.bottom, lessThan(rect.bottom));
    expect(contentRect.height, lessThan(rect.height));
  });

  test('chart drawable clip rect keeps drawing inside chart bounds', () {
    const rect = Rect.fromLTWH(2, 30, 316, 280);

    final clipRect = kLineDemoDrawableClipRect(rect, scrollOffset: 0);

    expect(clipRect, rect);
  });

  test('chart drawable clip rect follows scrolled content coordinates', () {
    const rect = Rect.fromLTWH(2, 30, 316, 280);

    final clipRect = kLineDemoDrawableClipRect(rect, scrollOffset: 120);

    expect(clipRect.left, 122);
    expect(clipRect.right, 438);
    expect(clipRect.top, rect.top);
    expect(clipRect.bottom, rect.bottom);
  });
}
