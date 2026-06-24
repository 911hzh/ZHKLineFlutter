import 'dart:math' as math;

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

  final List<T> dataSource;
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
  KLineChartContext<T>? _latestContext;
  bool _isUserScrollInProgress = false;

  @override
  void initState() {
    super.initState();
    _ownedController = KLineController();
    _controller = widget.controller ?? _ownedController;
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
      _controller.addListener(_handleControllerChange);
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
        final itemCount = widget.dataSource.length;
        if (itemCount == 0) {
          return widget.emptyBuilder?.call(context) ??
              const Center(child: Text('暂无数据'));
        }

        final itemExtent = _resolveItemExtent();
        final contentWidth = _resolveContentWidth(
          itemCount: itemCount,
          itemExtent: itemExtent,
          viewportWidth: viewportSize.width,
        );
        final visibleRange = KLineChartLayoutUtils.computeVisibleRange(
          itemCount: itemCount,
          itemExtent: itemExtent,
          viewportWidth: viewportSize.width,
          scrollOffset: _controller.scrollOffset,
        );
        final layoutNodesContext = _createContext(
          viewportSize: viewportSize,
          itemCount: itemCount,
          itemExtent: itemExtent,
          contentWidth: contentWidth,
          visibleRange: visibleRange,
          layoutNodes: const [],
        );
        final layoutNodes = widget.delegate.getLayoutNodes(
          layoutNodesContext,
          widget.dataSource,
        );
        final chartContext = _createContext(
          viewportSize: viewportSize,
          itemCount: itemCount,
          itemExtent: itemExtent,
          contentWidth: contentWidth,
          visibleRange: visibleRange,
          layoutNodes: layoutNodes,
        );
        _latestContext = chartContext;
        _syncVisibleRange(chartContext);

        final chartHeight = widget.delegate.chartHeight(chartContext);
        final selectedNode = chartContext.selectedNode;
        final overlayView = widget.delegate.buildOverlayView(
          context,
          chartContext,
        );
        final selectionView =
            selectedNode == null
                ? null
                : widget.delegate.buildSelectionView(
                  context,
                  chartContext,
                  selectedNode,
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
                NotificationListener<ScrollNotification>(
                  onNotification:
                      (notification) => _handleUserScrollNotification(
                        chartContext,
                        notification,
                      ),
                  child: SingleChildScrollView(
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

  double _resolveItemExtent() {
    return (widget.layout.candleWidth + widget.layout.candleSpacing) *
        _controller.scale;
  }

  double _resolveContentWidth({
    required int itemCount,
    required double itemExtent,
    required double viewportWidth,
  }) {
    final baseWidth = itemCount * itemExtent;
    final bodyWidth = math.max(
      1.0,
      widget.layout.scaledCandleWidth(_controller.scale),
    );
    final lastCandleTrailingEdge =
        (itemCount - 1) * itemExtent +
        itemExtent / 2 +
        widget.layout.chartPadding.left +
        bodyWidth / 2 +
        widget.layout.chartPadding.right;
    return math.max(viewportWidth, math.max(baseWidth, lastCandleTrailingEdge));
  }

  KLineChartContext<T> _createContext({
    required Size viewportSize,
    required int itemCount,
    required double itemExtent,
    required double contentWidth,
    required KLineVisibleRange visibleRange,
    required List<KLineLayoutNode<T>> layoutNodes,
  }) {
    return KLineChartContext<T>(
      controller: _controller,
      layout: widget.layout,
      theme: widget.theme,
      viewportSize: viewportSize,
      itemCount: itemCount,
      itemExtent: itemExtent,
      contentWidth: contentWidth,
      visibleRange: visibleRange,
      layoutNodes: layoutNodes,
    );
  }

  void _syncVisibleRange(KLineChartContext<T> context) {
    if (_controller.visibleRange == context.visibleRange) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.setVisibleRange(context.visibleRange);
    });
  }

  void _handleScroll() {
    _controller.setScrollOffset(_scrollController.offset);
    if (widget.behavior.clearSelectionOnScroll) {
      _controller.clearSelection();
    }
  }

  bool _handleUserScrollNotification(
    KLineChartContext<T> context,
    ScrollNotification notification,
  ) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _isUserScrollInProgress = notification.dragDetails != null;
      return false;
    }
    if (notification is ScrollEndNotification) {
      _isUserScrollInProgress = false;
      return false;
    }
    if (notification is! ScrollUpdateNotification || !_isUserScrollInProgress) {
      return false;
    }

    widget.delegate.didScroll(
      _latestContext ?? context,
      KLineScrollMetrics(
        pixels: metrics.pixels,
        minScrollExtent: metrics.minScrollExtent,
        maxScrollExtent: metrics.maxScrollExtent,
        viewportDimension: metrics.viewportDimension,
        scrollDelta: notification.scrollDelta ?? 0,
        extentBefore: metrics.extentBefore,
        extentAfter: metrics.extentAfter,
      ),
    );
    return false;
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
  }

  void _handleScaleUpdate(
    KLineChartContext<T> context,
    ScaleUpdateDetails details,
  ) {
    if (details.scale == 1) return;
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

  void _handleScaleEnd(KLineChartContext<T> context) {}

  void _handleControllerChange() {
    _syncScrollPositionFromController();
    if (mounted) setState(() {});
  }

  void _selectNearest(
    KLineChartContext<T> context,
    Offset localPosition, {
    required bool isMove,
  }) {
    if (context.layoutNodes.isEmpty) return;
    final x = localPosition.dx + _controller.scrollOffset;
    KLineLayoutNode<T>? nearest;
    var nearestDistance = double.infinity;
    for (final node in context.layoutNodes) {
      final distance = (node.centerX - x).abs();
      if (distance < nearestDistance) {
        nearest = node;
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
    delegate.drawChart(canvas, size, context);
  }

  @override
  bool shouldRepaint(covariant _KLineChartContentPainter<T> oldDelegate) {
    return oldDelegate.context != context || oldDelegate.delegate != delegate;
  }
}
