import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

void main() {
  testWidgets('content width includes the trailing candle body', (
    tester,
  ) async {
    final controller = KLineController(initialScrollOffset: 50);
    final delegate = _CapturingDefaultDelegate(adapter: const _IntAdapter());

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 50,
          height: 120,
          child: KLineChart<int>(
            controller: controller,
            dataSource: List.generate(10, (index) => index),
            delegate: delegate,
            layout: const KLineLayoutConfig(
              candleWidth: 8.5,
              candleSpacing: 1.5,
              mainChartHeight: 120,
            ),
          ),
        ),
      ),
    );

    final lastNode = delegate.lastNodes
        .whereType<KLineDefaultLayoutNode<int>>()
        .last;
    final trailingEdge = lastNode.centerX + lastNode.bodyWidth / 2;

    expect(trailingEdge, lessThanOrEqualTo(delegate.lastContext!.contentWidth));
  });

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

class _CapturingDefaultDelegate extends KLineDefaultDelegateImpl<int> {
  _CapturingDefaultDelegate({required super.adapter});

  KLineChartContext<int>? lastContext;
  List<KLineLayoutNode<int>> lastNodes = const [];

  @override
  List<KLineLayoutNode<int>> getLayoutNodes(
    KLineChartContext<int> context,
    List<int> dataSource,
  ) {
    lastContext = context;
    lastNodes = super.getLayoutNodes(context, dataSource);
    return lastNodes;
  }
}

class _IntAdapter extends KLineDataAdapter<int> {
  const _IntAdapter();

  @override
  double open(int item) => item.toDouble();

  @override
  double high(int item) => item + 1;

  @override
  double low(int item) => item - 1;

  @override
  double close(int item) => item + 0.5;

  @override
  double volume(int item) => item + 1;

  @override
  String dateLabel(int item) => '$item';
}
