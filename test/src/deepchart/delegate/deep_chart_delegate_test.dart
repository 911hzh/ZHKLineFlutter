import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/deepchart/adapter/deep_chart_data_adapter.dart';
import 'package:kline_flutter/src/deepchart/delegate/deep_chart_delegate.dart';
import 'package:kline_flutter/src/deepchart/model/deep_depth_entry.dart';
import 'package:kline_flutter/src/deepchart/theme/deep_chart_theme.dart';

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

  test('buildPositionedDepthNodes maps both sides around center gap', () {
    const nodes = DeepDepthNodes(
      bids: [
        DeepDepthNode(
          index: 0,
          entry: DeepDepthEntry(price: 100, size: 2),
          cumulativeSize: 2,
        ),
      ],
      asks: [
        DeepDepthNode(
          index: 0,
          entry: DeepDepthEntry(price: 101, size: 4),
          cumulativeSize: 4,
        ),
      ],
    );

    final positioned = DeepChartDefaultLayoutUtils.buildPositionedDepthNodes(
      nodes: nodes,
      contentRect: const Rect.fromLTWH(0, 0, 100, 100),
      centerGap: 2,
    );

    expect(positioned.bids.single.position?.dx, 49);
    expect(positioned.asks.single.position?.dx, 51);
    expect(positioned.asks.single.position?.dy, 0);
  });

  test('default grid segments stay inside the chart content rect', () {
    const layout = DeepChartLayoutConfig(
      mainHeight: 80,
      contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 16),
      gridHorizontalCount: 2,
      gridVerticalCount: 2,
    );
    final size = Size(160, layout.mainHeight + layout.bottomHeight);
    final contentRect = layout.contentRectFor(size);
    final lines = DeepChartDefaultLayoutUtils.buildGridLines(
      contentRect: contentRect,
      horizontalCount: layout.gridHorizontalCount,
      verticalCount: layout.gridVerticalCount,
    );

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
    expect(bottomLabels.last.rect.right, contentRect.right);
    expect(bottomLabels.last.textAlign, TextAlign.right);
  });

  test('bottom separator sits inside the total height', () {
    const layout = DeepChartLayoutConfig(
      mainHeight: 120,
      bottomHeight: 18,
      contentPadding: EdgeInsets.zero,
    );

    final line = DeepChartDefaultLayoutUtils.buildBottomSeparatorLine(
      contentRect: layout.contentRectFor(const Size(200, 138)),
      totalHeight: layout.mainHeight + layout.bottomHeight,
    );

    expect(line.start.dy, 137.5);
    expect(line.end.dy, 137.5);
  });

  test(
    'default delegate getLayoutNodes reads business data through adapter',
    () {
      const delegate = _Delegate<_Level>();
      final context = DeepChartContext<_Level>(
        bids: const [_Level(100, 2)],
        asks: const [_Level(101, 3)],
        adapter: const _Adapter(),
        theme: const DeepChartTheme(),
        layout: const DeepChartLayoutConfig(mainHeight: 80),
        viewportSize: const Size(160, 96),
        nodes: const DeepDepthNodes(bids: [], asks: []),
      );

      final nodes = delegate.getLayoutNodes(context);

      expect(nodes.bids.single.price, 100);
      expect(nodes.bids.single.cumulativeSize, 2);
      expect(nodes.bids.single.position, isNotNull);
      expect(nodes.asks.single.price, 101);
    },
  );
}

bool _containsInclusive(Rect rect, Offset offset) {
  return offset.dx >= rect.left &&
      offset.dx <= rect.right &&
      offset.dy >= rect.top &&
      offset.dy <= rect.bottom;
}

class _Level {
  const _Level(this.price, this.size);

  final double price;
  final double size;
}

class _Adapter extends DeepChartDataAdapter<_Level> {
  const _Adapter();

  @override
  double price(_Level item) => item.price;

  @override
  double size(_Level item) => item.size;
}

class _Delegate<T> extends DeepChartDelegate<T> {
  const _Delegate();
}
