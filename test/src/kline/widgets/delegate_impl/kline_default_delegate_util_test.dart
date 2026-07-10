import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_data_adapter.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_default_delegate_util.dart';

void main() {
  test('chartHeight sums active secondary pane heights and selector', () {
    final context = _context();
    const volume = KLineIndicatorSpec<_Candle>(id: 'volume', label: 'VOL');
    const cci = KLineIndicatorSpec<_Candle>(
      id: 'cci',
      label: 'CCI',
      height: 88,
    );

    expect(
      KLineDefaultDelegateImplUtil.chartHeight(
        context,
        secondaryIndicators: const [volume, cci],
        indicatorHeight:
            (_, indicator) =>
                indicator.height ?? context.layout.secondaryPaneHeight,
      ),
      100 + 70 + 88 + 40,
    );
  });

  test('default layout nodes respect main chart content padding', () {
    const layout = KLineLayoutConfig(
      mainChartHeight: 100,
      contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 40),
    );
    final context = _context(layout: layout);
    const candle = _Candle(open: 5, high: 10, low: 0, close: 5, volume: 100);

    final nodes = KLineDefaultDelegateImplUtil.getLayoutNodes(
      context,
      [candle],
      adapter: const _Adapter(),
      mainIndicators: const <KLineIndicatorSpec<_Candle>>[],
    );
    final node = nodes.single as KLineDefaultLayoutNode<_Candle>;

    expect(node.highY, layout.contentPadding.top);
    expect(node.lowY, layout.mainChartHeight - layout.contentPadding.bottom);
  });

  test('default layout range includes active BOLL values', () {
    const layout = KLineLayoutConfig(
      mainChartHeight: 100,
      contentPadding: EdgeInsets.fromLTRB(0, 10, 0, 10),
    );
    final context = _context(
      controller: KLineController(
        initialIndicators: const [KLineDefaultIndicators.bollId],
      ),
      layout: layout,
    );
    const candle = _Candle(open: 5, high: 10, low: 0, close: 5, volume: 100);

    final nodes = KLineDefaultDelegateImplUtil.getLayoutNodes(
      context,
      [candle],
      adapter: const _Adapter(),
      mainIndicators: KLineDefaultIndicators.main<_Candle>(),
    );
    final node = nodes.single as KLineDefaultLayoutNode<_Candle>;

    expect(node.highY, greaterThan(layout.contentPadding.top));
    expect(
      node.lowY,
      lessThan(layout.mainChartHeight - layout.contentPadding.bottom),
    );
  });

  test('default volume range includes volume moving averages', () {
    const candle = _Candle(open: 10, high: 12, low: 9, close: 11, volume: 100);
    final context = _context(
      layoutNodes: const [
        KLineLayoutNode<_Candle>(
          index: 0,
          item: candle,
          frame: Rect.fromLTWH(0, 0, 10, 180),
        ),
      ],
    );

    final range = KLineDefaultDelegateImplUtil.indicatorRange(
      context,
      KLineDefaultIndicators.volume<_Candle>(),
      adapter: const _HighVolumeMaAdapter(),
    );

    expect(range, (0, 200));
  });

  test('clip and secondary content helpers stay inside input rects', () {
    const rect = Rect.fromLTWH(10, 20, 100, 40);

    expect(
      kLineDefaultDrawableClipRect(rect, scrollOffset: 30),
      rect.shift(const Offset(30, 0)),
    );

    final content = kLineDefaultSecondaryContentRect(
      rect,
      layout: const KLineLayoutConfig(secondaryContentVerticalPadding: 12),
    );

    expect(content.top, 32);
    expect(content.bottom, 48);
  });

  test('default cross line uses selected node content x in content layer', () {
    const candle = _Candle(open: 10, high: 12, low: 9, close: 11, volume: 100);
    final controller =
        KLineController()
          ..setScrollOffset(100)
          ..selectIndex(
            0,
            localPosition: const Offset(50, 60),
            contentPosition: const Offset(120, 60),
          );
    final context = _context(
      controller: controller,
      layout: const KLineLayoutConfig(chartPadding: EdgeInsets.zero),
      contentWidth: 300,
      layoutNodes: const [
        KLineDefaultLayoutNode<_Candle>(
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

KLineChartContext<_Candle> _context({
  KLineController? controller,
  KLineLayoutConfig layout = const KLineLayoutConfig(mainChartHeight: 100),
  double contentWidth = 10,
  List<KLineLayoutNode<_Candle>> layoutNodes = const [],
}) {
  return KLineChartContext<_Candle>(
    controller: controller ?? KLineController(),
    layout: layout,
    theme: const KLineTheme(),
    viewportSize: const Size(120, 180),
    itemCount: 1,
    itemExtent: 10,
    contentWidth: contentWidth,
    visibleRange: const KLineVisibleRange(start: 0, end: 0),
    layoutNodes: layoutNodes,
  );
}

class _Candle {
  const _Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
}

class _Adapter extends KLineDataAdapter<_Candle> {
  const _Adapter();

  @override
  double open(_Candle item) => item.open;

  @override
  double high(_Candle item) => item.high;

  @override
  double low(_Candle item) => item.low;

  @override
  double close(_Candle item) => item.close;

  @override
  double volume(_Candle item) => item.volume;

  @override
  String dateLabel(_Candle item) => 'T';

  @override
  double? indicatorValue(_Candle item, String valueId) {
    return switch (valueId) {
      KLineDefaultIndicators.bollUpper => item.high + 10,
      KLineDefaultIndicators.bollMiddle => item.close,
      KLineDefaultIndicators.bollLower => item.low - 10,
      KLineDefaultIndicators.volumeMA5 => item.volume,
      _ => null,
    };
  }
}

class _HighVolumeMaAdapter extends _Adapter {
  const _HighVolumeMaAdapter();

  @override
  double? indicatorValue(_Candle item, String valueId) {
    return switch (valueId) {
      KLineDefaultIndicators.volumeMA5 => item.volume * 2,
      _ => super.indicatorValue(item, valueId),
    };
  }
}
