import 'package:flutter/material.dart';

import '../controller/kline_controller.dart';
import '../theme/kline_theme.dart';

@immutable
class KLineVisibleItem<T> {
  const KLineVisibleItem({
    required this.index,
    required this.item,
    required this.frame,
  });

  final int index;
  final T item;
  final Rect frame;

  Offset get center => frame.center;
  double get centerX => frame.center.dx;
}

@immutable
class KLineDataRequest {
  const KLineDataRequest({required this.visibleRange, required this.reason});

  final KLineVisibleRange visibleRange;
  final KLineDataRequestReason reason;
}

enum KLineDataRequestReason { initial, scroll, scale, reload }

class KLineChartContext<T> {
  const KLineChartContext({
    required this.controller,
    required this.layout,
    required this.theme,
    required this.viewportSize,
    required this.itemCount,
    required this.itemExtent,
    required this.contentWidth,
    required this.visibleRange,
    required this.visibleItems,
  });

  final KLineController controller;
  final KLineLayoutConfig layout;
  final KLineTheme theme;
  final Size viewportSize;
  final int itemCount;
  final double itemExtent;
  final double contentWidth;
  final KLineVisibleRange visibleRange;
  final List<KLineVisibleItem<T>> visibleItems;

  KLineVisibleItem<T>? get selectedItem {
    final selectedIndex = controller.selectedIndex;
    if (selectedIndex == null) return null;
    for (final item in visibleItems) {
      if (item.index == selectedIndex) return item;
    }
    return null;
  }
}

/// Supplies chart data on demand, similar to UITableViewDataSource.
abstract class KLineChartDataSource<T> {
  const KLineChartDataSource();

  int numberOfItems(KLineChartContext<T> context);

  T itemAt(KLineChartContext<T> context, int index);

  void chartDidRequestData(
    KLineChartContext<T> context,
    KLineDataRequest request,
  ) {}
}

/// Controls drawing, sizing, selection UI, and interaction callbacks.
///
/// The package core intentionally does not draw K-line business content.
/// Implementors decide how to draw grid, candles, indicators, overlays, and
/// selection views.
abstract class KLineChartDelegate<T> {
  const KLineChartDelegate();

  double itemExtent(KLineChartContext<T> context) {
    return context.layout.candleWidth * context.controller.scale +
        context.layout.candleSpacing * context.controller.scale;
  }

  double chartHeight(KLineChartContext<T> context) {
    return context.layout.mainChartHeight;
  }

  void drawGrid(Canvas canvas, Size size, KLineChartContext<T> context) {}

  void drawItem(
    Canvas canvas,
    Size size,
    KLineChartContext<T> context,
    KLineVisibleItem<T> item,
  ) {}

  void drawOverlay(Canvas canvas, Size size, KLineChartContext<T> context) {}

  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<T> chartContext,
    KLineVisibleItem<T> selectedItem,
  ) {
    return null;
  }

  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<T> chartContext,
  ) {
    return null;
  }

  void didUpdateVisibleRange(
    KLineChartContext<T> context,
    KLineVisibleRange visibleRange,
  ) {}

  void didSelectItem(KLineChartContext<T> context, KLineVisibleItem<T> item) {}

  void didMoveSelection(
    KLineChartContext<T> context,
    KLineVisibleItem<T> item,
  ) {}

  void didStartScale(KLineChartContext<T> context, double scale) {}

  void didUpdateScale(KLineChartContext<T> context, double scale) {}

  void didEndScale(KLineChartContext<T> context, double scale) {}

  void didEndInteraction(KLineChartContext<T> context) {}
}
