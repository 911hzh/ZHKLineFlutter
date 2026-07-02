import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kline_flutter/src/kline/controller/kline_controller.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/theme/kline_theme.dart';

class ScaleLayoutMetrics {
  const ScaleLayoutMetrics({
    required this.itemExtent,
    required this.contentWidth,
    required this.scrollOffset,
  });

  final double itemExtent;
  final double contentWidth;
  final double scrollOffset;
}

/// 处理 K 线图缩放手势中的状态记录和 offset 计算。
class ScaleGestureHandler {
  double _baseScale = 1;
  double _scaleStartLocalFocalX = 0;
  double _scaleStartContentFocalX = 0;
  double? _lastLayoutScale;

  ScaleLayoutMetrics resolveLayout({
    required KLineController controller,
    required KLineLayoutConfig layout,
    required int itemCount,
    required double viewportWidth,
  }) {
    final itemExtent = resolveItemExtent(
      layout: layout,
      scale: controller.scale,
    );
    final contentWidth = resolveContentWidth(
      layout: layout,
      itemCount: itemCount,
      itemExtent: itemExtent,
      viewportWidth: viewportWidth,
      scale: controller.scale,
    );
    final scaleChanged =
        _lastLayoutScale != null && _lastLayoutScale != controller.scale;
    final scrollOffset =
        scaleChanged
            ? resolveScrollOffset(
              controller: controller,
              contentWidth: contentWidth,
              viewportWidth: viewportWidth,
            )
            : controller.scrollOffset;
    _lastLayoutScale = controller.scale;
    return ScaleLayoutMetrics(
      itemExtent: itemExtent,
      contentWidth: contentWidth,
      scrollOffset: scrollOffset,
    );
  }

  /// 记录缩放起点，用于后续围绕同一个焦点计算滚动偏移。
  void handleStart({
    required KLineController controller,
    required ScaleStartDetails details,
  }) {
    _baseScale = controller.scale;
    _scaleStartLocalFocalX = details.localFocalPoint.dx;
    _scaleStartContentFocalX = controller.scrollOffset + _scaleStartLocalFocalX;
  }

  /// 根据手势缩放比例更新 controller 的 scale 和 scrollOffset。
  void handleUpdate<T>({
    required KLineController controller,
    required KLineLayoutConfig layout,
    required KLineChartContext<T> context,
    required ScaleUpdateDetails details,
  }) {
    if (details.scale == 1) return;

    final nextScale = (_baseScale * details.scale).clamp(
      layout.minScale,
      layout.maxScale,
    );
    final nextItemExtent = resolveItemExtent(layout: layout, scale: nextScale);
    final nextContentWidth = resolveContentWidth(
      layout: layout,
      itemCount: context.itemCount,
      itemExtent: nextItemExtent,
      viewportWidth: context.viewportSize.width,
      scale: nextScale,
    );
    final maxScrollOffset = math.max(
      0.0,
      nextContentWidth - context.viewportSize.width,
    );

    controller.setScaleAroundFocalPoint(
      scale: nextScale,
      baseScale: _baseScale,
      localFocalX: _scaleStartLocalFocalX,
      contentFocalX: _scaleStartContentFocalX,
      minScrollOffset: 0,
      maxScrollOffset: maxScrollOffset,
    );
  }

  /// 当内容宽度变化导致当前 offset 越界时，把 controller 拉回本帧使用的合法值。
  void syncScrollOffsetBounds({
    required KLineController controller,
    required double scrollOffset,
    required bool Function() isMounted,
  }) {
    if (controller.scrollOffset == scrollOffset) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted()) return;
      controller.setScrollOffset(scrollOffset);
    });
  }

  double resolveItemExtent({
    required KLineLayoutConfig layout,
    required double scale,
  }) {
    return (layout.candleWidth + layout.candleSpacing) * scale;
  }

  double resolveContentWidth({
    required KLineLayoutConfig layout,
    required int itemCount,
    required double itemExtent,
    required double viewportWidth,
    required double scale,
  }) {
    final baseWidth = itemCount * itemExtent;
    final bodyWidth = math.max(1.0, layout.scaledCandleWidth(scale));
    final lastCandleTrailingEdge =
        (itemCount - 1) * itemExtent +
        itemExtent / 2 +
        layout.chartPadding.left +
        bodyWidth / 2 +
        layout.chartPadding.right;
    return math.max(viewportWidth, math.max(baseWidth, lastCandleTrailingEdge));
  }

  double resolveScrollOffset({
    required KLineController controller,
    required double contentWidth,
    required double viewportWidth,
  }) {
    final maxScrollOffset = math.max(0.0, contentWidth - viewportWidth);
    return controller.scrollOffset.clamp(0.0, maxScrollOffset).toDouble();
  }
}
