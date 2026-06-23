import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

void main() {
  test('secondary indicator content rect reserves top and bottom padding', () {
    const rect = Rect.fromLTWH(2, 342, 316, 70);
    const layout = KLineLayoutConfig(secondaryContentVerticalPadding: 14);

    final contentRect = kLineDefaultSecondaryContentRect(rect, layout: layout);

    expect(contentRect.left, rect.left);
    expect(contentRect.right, rect.right);
    expect(contentRect.top, rect.top + 14);
    expect(contentRect.bottom, rect.bottom - 14);
    expect(contentRect.height, rect.height - 28);
  });

  test('chart drawable clip rect keeps drawing inside chart bounds', () {
    const rect = Rect.fromLTWH(2, 30, 316, 280);

    final clipRect = kLineDefaultDrawableClipRect(rect, scrollOffset: 0);

    expect(clipRect, rect);
  });

  test('chart drawable clip rect follows scrolled content coordinates', () {
    const rect = Rect.fromLTWH(2, 30, 316, 280);

    final clipRect = kLineDefaultDrawableClipRect(rect, scrollOffset: 120);

    expect(clipRect.left, 122);
    expect(clipRect.right, 438);
    expect(clipRect.top, rect.top);
    expect(clipRect.bottom, rect.bottom);
  });
}
