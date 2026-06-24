import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/k_line_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  test(
    'buildCumulativeDepthNodes accumulates bid and ask sizes independently',
    () {
      final nodes = DeepChartDefaultLayoutUtils.buildCumulativeDepthNodes(
        bids: const [
          DeepDepthEntry(price: 100, size: 2),
          DeepDepthEntry(price: 99, size: 3),
        ],
        asks: const [
          DeepDepthEntry(price: 101, size: 4),
          DeepDepthEntry(price: 102, size: 5),
        ],
      );

      expect(nodes.bids.map((node) => node.cumulativeSize), [2, 5]);
      expect(nodes.asks.map((node) => node.cumulativeSize), [4, 9]);
      expect(nodes.maxCumulativeSize, 9);
      expect(nodes.minPrice, 99);
      expect(nodes.maxPrice, 102);
    },
  );

  test('default grid segments stay inside the chart content rect', () {
    const layout = DeepChartLayoutConfig(
      mainHeight: 80,
      contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 16),
      gridHorizontalCount: 2,
      gridVerticalCount: 2,
    );
    final size = Size(160, layout.mainHeight + layout.bottomHeight);
    final lines = DeepChartDefaultLayoutUtils.buildGridLines(
      contentRect: layout.contentRectFor(size),
      horizontalCount: layout.gridHorizontalCount,
      verticalCount: layout.gridVerticalCount,
    );

    final contentRect = layout.contentRectFor(size);
    expect(lines, isNotEmpty);
    for (final line in lines) {
      expect(_containsInclusive(contentRect, line.start), isTrue);
      expect(_containsInclusive(contentRect, line.end), isTrue);
    }
  });

  test('axis labels align to grid lines and use a separate bottom row', () {
    const layout = DeepChartLayoutConfig(
      mainHeight: 80,
      contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 16),
      gridHorizontalCount: 2,
      priceLabelCount: 3,
    );
    final size = Size(160, layout.mainHeight + layout.bottomHeight);
    final contentRect = layout.contentRectFor(size);

    final rightLabels = DeepChartDefaultLayoutUtils.buildRightAxisLabelOffsets(
      contentRect: contentRect,
      chartWidth: size.width,
      labelHeight: 10,
      horizontalCount: layout.gridHorizontalCount,
    );
    final bottomLabels =
        DeepChartDefaultLayoutUtils.buildBottomPriceLabelLayouts(
          contentRect: contentRect,
          chartWidth: size.width,
          rowTop: layout.mainHeight,
          rowHeight: layout.bottomHeight,
          bottomPadding: layout.contentPadding.bottom,
          priceLabelCount: layout.priceLabelCount,
          verticalCount: layout.gridVerticalCount,
        );

    expect(rightLabels.first.dy, contentRect.top - 10);
    expect(rightLabels.last.dy, contentRect.bottom - 10);
    expect(bottomLabels.first.rect.left, contentRect.left);
    expect(bottomLabels.first.textAlign, TextAlign.left);
    expect(
      bottomLabels[1].rect.center.dx,
      contentRect.left + contentRect.width / layout.gridVerticalCount,
    );
    expect(bottomLabels[1].textAlign, TextAlign.center);
    expect(bottomLabels.last.rect.right, contentRect.right);
    expect(bottomLabels.last.textAlign, TextAlign.right);
    for (final label in bottomLabels) {
      expect(label.rect.top, layout.mainHeight);
      expect(
        label.rect.height,
        layout.bottomHeight - layout.contentPadding.bottom,
      );
    }
  });

  test(
    'content rect reserves bottom label row even without bottom padding',
    () {
      const layout = DeepChartLayoutConfig(
        mainHeight: 80,
        contentPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
      );
      final size = Size(160, layout.mainHeight + layout.bottomHeight);

      final contentRect = layout.contentRectFor(size);
      final bottomLabels =
          DeepChartDefaultLayoutUtils.buildBottomPriceLabelLayouts(
            contentRect: contentRect,
            chartWidth: size.width,
            rowTop: layout.mainHeight,
            rowHeight: layout.bottomHeight,
            bottomPadding: layout.contentPadding.bottom,
            priceLabelCount: layout.priceLabelCount,
            verticalCount: layout.gridVerticalCount,
          );

      expect(contentRect.bottom, lessThan(size.height));
      for (final label in bottomLabels) {
        expect(
          label.rect.bottom,
          lessThanOrEqualTo(size.height - layout.contentPadding.bottom),
        );
      }
    },
  );

  test('bottom label row leaves bottom padding below text area', () {
    const layout = DeepChartLayoutConfig(
      mainHeight: 120,
      bottomHeight: 24,
      contentPadding: EdgeInsets.only(bottom: 8),
    );
    final labels = DeepChartDefaultLayoutUtils.buildBottomPriceLabelLayouts(
      contentRect: layout.contentRectFor(const Size(200, 144)),
      chartWidth: 200,
      rowTop: layout.mainHeight,
      rowHeight: layout.bottomHeight,
      bottomPadding: layout.contentPadding.bottom,
      priceLabelCount: layout.priceLabelCount,
      verticalCount: layout.gridVerticalCount,
    );

    expect(labels.first.rect.top, 120);
    expect(labels.first.rect.bottom, 136);
  });

  test('layout total height is chart height plus bottom label height', () {
    const layout = DeepChartLayoutConfig(
      mainHeight: 120,
      bottomHeight: 18,
      contentPadding: EdgeInsets.zero,
    );

    expect(layout.mainHeight + layout.bottomHeight, 138);
    expect(layout.contentRectFor(const Size(200, 138)).bottom, 120);
  });

  test('bottom separator sits below the bottom label row', () {
    const layout = DeepChartLayoutConfig(
      mainHeight: 120,
      bottomHeight: 18,
      contentPadding: EdgeInsets.zero,
    );

    final line = DeepChartDefaultLayoutUtils.buildBottomSeparatorLine(
      contentRect: layout.contentRectFor(const Size(200, 138)),
      totalHeight: layout.mainHeight + layout.bottomHeight,
    );

    expect(line.start.dy, layout.mainHeight + layout.bottomHeight - 0.5);
    expect(line.end.dy, layout.mainHeight + layout.bottomHeight - 0.5);
  });
}

bool _containsInclusive(Rect rect, Offset offset) {
  return offset.dx >= rect.left &&
      offset.dx <= rect.right &&
      offset.dy >= rect.top &&
      offset.dy <= rect.bottom;
}
