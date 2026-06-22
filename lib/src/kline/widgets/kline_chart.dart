import 'package:flutter/material.dart';

import '../controller/kline_controller.dart';
import '../delegate/kline_chart_delegate.dart';
import '../theme/kline_theme.dart';

class KLineChart<T> extends StatefulWidget {
  const KLineChart({
    super.key,
    required this.dataSource,
    required this.delegate,
    this.controller,
    this.theme = const KLineTheme(),
    this.layout = const KLineLayoutConfig(),
    this.behavior = const KLineBehaviorConfig(),
    this.loadingBuilder,
    this.emptyBuilder,
    this.isLoading = false,
  });

  final KLineChartDataSource<T> dataSource;
  final KLineChartDelegate<T> delegate;
  final KLineController? controller;
  final KLineTheme theme;
  final KLineLayoutConfig layout;
  final KLineBehaviorConfig behavior;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final bool isLoading;

  @override
  State<KLineChart<T>> createState() => _KLineChartState<T>();
}

class _KLineChartState<T> extends State<KLineChart<T>> {
  late final KLineController _ownedController;
  late KLineController _controller;
  final ScrollController _scrollController = ScrollController();
  double _baseScale = 1;
  double _scaleStartLocalFocalX = 0;
  double _scaleStartContentFocalX = 0;
  late double _lastReportedScale;
  KLineDataRequestReason _requestReason = KLineDataRequestReason.initial;
  KLineChartContext<T>? _latestContext;

  @override
  void initState() {
    super.initState();
    _ownedController = KLineController();
    _controller = widget.controller ?? _ownedController;
    _lastReportedScale = _controller.scale;
    _scrollController.addListener(_handleScroll);
    _controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant KLineChart<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextController = widget.controller ?? _ownedController;
    if (nextController != _controller) {
      _controller.removeListener(_handleControllerChange);
      _controller = nextController;
      _lastReportedScale = _controller.scale;
      _controller.addListener(_handleControllerChange);
    }
    if (oldWidget.dataSource != widget.dataSource) {
      _requestReason = KLineDataRequestReason.reload;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _ownedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = _resolveViewportSize(context, constraints);
        final seedContext = _createContext(
          viewportSize: viewportSize,
          itemCount: 0,
          itemExtent: widget.layout.candleWidth + widget.layout.candleSpacing,
          visibleRange: const KLineVisibleRange(start: 0, end: 0),
          visibleItems: const [],
        );
        final itemCount = widget.dataSource.numberOfItems(seedContext);
        if (itemCount == 0) {
          return widget.emptyBuilder?.call(context) ??
              const Center(child: Text('暂无数据'));
        }

        final itemExtent = widget.delegate.itemExtent(
          _createContext(
            viewportSize: viewportSize,
            itemCount: itemCount,
            itemExtent: widget.layout.candleWidth + widget.layout.candleSpacing,
            visibleRange: const KLineVisibleRange(start: 0, end: 0),
            visibleItems: const [],
          ),
        );
        final visibleRange = _computeVisibleRange(
          itemCount: itemCount,
          itemExtent: itemExtent,
          viewportWidth: viewportSize.width,
        );
        final visibleItems = _buildVisibleItems(
          itemCount: itemCount,
          itemExtent: itemExtent,
          viewportSize: viewportSize,
          visibleRange: visibleRange,
        );
        final chartContext = _createContext(
          viewportSize: viewportSize,
          itemCount: itemCount,
          itemExtent: itemExtent,
          visibleRange: visibleRange,
          visibleItems: visibleItems,
        );
        _latestContext = chartContext;
        _syncVisibleRange(chartContext);

        final chartHeight = widget.delegate.chartHeight(chartContext);
        final contentWidth = (itemCount * itemExtent).clamp(
          viewportSize.width,
          double.infinity,
        );
        final selectedItem = chartContext.selectedItem;
        final overlayView = widget.delegate.buildOverlayView(
          context,
          chartContext,
        );
        final selectionView =
            selectedItem == null
                ? null
                : widget.delegate.buildSelectionView(
                  context,
                  chartContext,
                  selectedItem,
                );

        return SizedBox(
          height: chartHeight,
          child: GestureDetector(
            onScaleStart:
                widget.behavior.enableScale
                    ? (details) => _handleScaleStart(chartContext, details)
                    : null,
            onScaleUpdate:
                widget.behavior.enableScale
                    ? (details) => _handleScaleUpdate(chartContext, details)
                    : null,
            onScaleEnd:
                widget.behavior.enableScale
                    ? (_) => _handleScaleEnd(chartContext)
                    : null,
            onTapUp:
                widget.behavior.enableCrosshair
                    ? (details) => _selectNearest(
                      chartContext,
                      details.localPosition,
                      isMove: false,
                    )
                    : null,
            onLongPressStart:
                widget.behavior.enableCrosshair
                    ? (details) => _selectNearest(
                      chartContext,
                      details.localPosition,
                      isMove: false,
                    )
                    : null,
            onLongPressMoveUpdate:
                widget.behavior.enableCrosshair
                    ? (details) => _selectNearest(
                      chartContext,
                      details.localPosition,
                      isMove: true,
                    )
                    : null,
            onLongPressEnd: (_) => _endInteraction(chartContext),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _KLineChartFixedPainter<T>(
                        context: chartContext,
                        delegate: widget.delegate,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    height: chartHeight,
                    child: CustomPaint(
                      painter: _KLineChartContentPainter<T>(
                        context: chartContext,
                        delegate: widget.delegate,
                      ),
                    ),
                  ),
                ),
                if (overlayView != null) overlayView,
                if (selectionView != null) selectionView,
              ],
            ),
          ),
        );
      },
    );
  }

  Size _resolveViewportSize(BuildContext context, BoxConstraints constraints) {
    final mediaSize = MediaQuery.sizeOf(context);
    final width =
        constraints.maxWidth.isFinite ? constraints.maxWidth : mediaSize.width;
    final height =
        constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : widget.layout.mainChartHeight;
    return Size(width, height);
  }

  KLineChartContext<T> _createContext({
    required Size viewportSize,
    required int itemCount,
    required double itemExtent,
    required KLineVisibleRange visibleRange,
    required List<KLineVisibleItem<T>> visibleItems,
  }) {
    return KLineChartContext<T>(
      controller: _controller,
      layout: widget.layout,
      theme: widget.theme,
      viewportSize: viewportSize,
      itemCount: itemCount,
      itemExtent: itemExtent,
      contentWidth: itemCount * itemExtent,
      visibleRange: visibleRange,
      visibleItems: visibleItems,
    );
  }

  KLineVisibleRange _computeVisibleRange({
    required int itemCount,
    required double itemExtent,
    required double viewportWidth,
  }) {
    final start = (_controller.scrollOffset / itemExtent).floor().clamp(
      0,
      itemCount - 1,
    );
    final visibleCount = (viewportWidth / itemExtent).ceil() + 1;
    final end = (start + visibleCount).clamp(start, itemCount - 1);
    return KLineVisibleRange(start: start, end: end);
  }

  List<KLineVisibleItem<T>> _buildVisibleItems({
    required int itemCount,
    required double itemExtent,
    required Size viewportSize,
    required KLineVisibleRange visibleRange,
  }) {
    final context = _createContext(
      viewportSize: viewportSize,
      itemCount: itemCount,
      itemExtent: itemExtent,
      visibleRange: visibleRange,
      visibleItems: const [],
    );
    final items = <KLineVisibleItem<T>>[];
    for (var index = visibleRange.start; index <= visibleRange.end; index++) {
      final left = index * itemExtent;
      items.add(
        KLineVisibleItem<T>(
          index: index,
          item: widget.dataSource.itemAt(context, index),
          frame: Rect.fromLTWH(left, 0, itemExtent, viewportSize.height),
        ),
      );
    }
    return items;
  }

  void _syncVisibleRange(KLineChartContext<T> context) {
    if (_controller.visibleRange == context.visibleRange) return;
    final reason = _requestReason;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.setVisibleRange(context.visibleRange);
      widget.delegate.didUpdateVisibleRange(context, context.visibleRange);
      widget.dataSource.chartDidRequestData(
        context,
        KLineDataRequest(visibleRange: context.visibleRange, reason: reason),
      );
      _requestReason = KLineDataRequestReason.scroll;
    });
  }

  void _handleScroll() {
    _requestReason = KLineDataRequestReason.scroll;
    _controller.setScrollOffset(_scrollController.offset);
    if (widget.behavior.clearSelectionOnScroll) {
      _controller.clearSelection();
    }
  }

  void _syncScrollPositionFromController() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target =
        _controller.scrollOffset
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if ((position.pixels - target).abs() < 0.5) return;
    _scrollController.jumpTo(target);
  }

  void _handleScaleStart(
    KLineChartContext<T> context,
    ScaleStartDetails details,
  ) {
    _baseScale = _controller.scale;
    _scaleStartLocalFocalX = details.localFocalPoint.dx;
    _scaleStartContentFocalX =
        _controller.scrollOffset + _scaleStartLocalFocalX;
    widget.delegate.didStartScale(context, _controller.scale);
  }

  void _handleScaleUpdate(
    KLineChartContext<T> context,
    ScaleUpdateDetails details,
  ) {
    if (details.scale == 1) return;
    _requestReason = KLineDataRequestReason.scale;
    final nextScale = (_baseScale * details.scale).clamp(
      widget.layout.minScale,
      widget.layout.maxScale,
    );
    _controller.setScaleAroundFocalPoint(
      scale: nextScale,
      baseScale: _baseScale,
      localFocalX: _scaleStartLocalFocalX,
      contentFocalX: _scaleStartContentFocalX,
    );
  }

  void _handleScaleEnd(KLineChartContext<T> context) {
    widget.delegate.didEndScale(_latestContext ?? context, _controller.scale);
  }

  void _handleControllerChange() {
    _syncScrollPositionFromController();
    if (_lastReportedScale != _controller.scale) {
      _requestReason = KLineDataRequestReason.scale;
      _lastReportedScale = _controller.scale;
      final context = _latestContext;
      if (context != null) {
        widget.delegate.didUpdateScale(context, _controller.scale);
      }
    }
    if (mounted) setState(() {});
  }

  void _selectNearest(
    KLineChartContext<T> context,
    Offset localPosition, {
    required bool isMove,
  }) {
    if (context.visibleItems.isEmpty) return;
    final x = localPosition.dx + _controller.scrollOffset;
    KLineVisibleItem<T>? nearest;
    var nearestDistance = double.infinity;
    for (final item in context.visibleItems) {
      final distance = (item.centerX - x).abs();
      if (distance < nearestDistance) {
        nearest = item;
        nearestDistance = distance;
      }
    }
    if (nearest == null) return;
    _controller.selectIndex(
      nearest.index,
      localPosition: localPosition,
      contentPosition: Offset(x, localPosition.dy),
    );
    if (isMove) {
      widget.delegate.didMoveSelection(context, nearest);
    } else {
      widget.delegate.didSelectItem(context, nearest);
    }
  }

  void _endInteraction(KLineChartContext<T> context) {
    widget.delegate.didEndInteraction(_latestContext ?? context);
    if (!widget.behavior.keepCrosshairOnLongPressEnd) {
      _controller.clearSelection();
    }
  }
}

class _KLineChartFixedPainter<T> extends CustomPainter {
  const _KLineChartFixedPainter({
    required this.context,
    required this.delegate,
  });

  final KLineChartContext<T> context;
  final KLineChartDelegate<T> delegate;

  @override
  void paint(Canvas canvas, Size size) {
    delegate.drawGrid(canvas, size, context);
    delegate.drawOverlay(canvas, size, context);
  }

  @override
  bool shouldRepaint(covariant _KLineChartFixedPainter<T> oldDelegate) {
    return oldDelegate.context != context || oldDelegate.delegate != delegate;
  }
}

class _KLineChartContentPainter<T> extends CustomPainter {
  const _KLineChartContentPainter({
    required this.context,
    required this.delegate,
  });

  final KLineChartContext<T> context;
  final KLineChartDelegate<T> delegate;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in context.visibleItems) {
      delegate.drawItem(canvas, size, context, item);
    }
  }

  @override
  bool shouldRepaint(covariant _KLineChartContentPainter<T> oldDelegate) {
    return oldDelegate.context != context || oldDelegate.delegate != delegate;
  }
}
