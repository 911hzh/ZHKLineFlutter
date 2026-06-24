import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controller/kline_controller.dart';
import '../delegate/kline_chart_delegate.dart';
import '../theme/kline_theme.dart';

/// K 线图核心组件。
///
/// 该组件负责横向滚动、缩放、选中、可见区计算和绘制调度。
/// 具体的网格、蜡烛、指标、覆盖层和选中详情都交给 [delegate] 实现，
/// 因此业务方可以在不修改 core chart 的情况下替换任意绘制层。
class KLineChart<T> extends StatefulWidget {
  /// 创建一个 K 线核心图表。
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

  /// 需要绘制的数据源。
  ///
  /// 图表本身不关心数据模型字段，字段读取和布局节点生成由 [delegate] 决定。
  final List<T> dataSource;

  /// 图表绘制和交互代理。
  ///
  /// delegate 负责高度计算、布局节点、固定网格、滚动内容、覆盖层和选中 UI。
  final KLineChartDelegate<T> delegate;

  /// 外部控制器。
  ///
  /// 如果不传入，组件会创建内部控制器；传入后外部可以读取或驱动缩放、
  /// 滚动、选中项、可见区和指标状态。
  final KLineController? controller;

  /// 图表主题配置。
  final KLineTheme theme;

  /// 图表布局配置。
  final KLineLayoutConfig layout;

  /// 图表交互行为配置。
  final KLineBehaviorConfig behavior;

  /// 自定义加载态 UI。
  final WidgetBuilder? loadingBuilder;

  /// 自定义空数据 UI。
  final WidgetBuilder? emptyBuilder;

  /// 是否展示加载态。
  final bool isLoading;

  @override
  State<KLineChart<T>> createState() => _KLineChartState<T>();
}

class _KLineChartState<T> extends State<KLineChart<T>> {
  /// 当外部没有传入 controller 时，由组件自己持有并释放。
  late final KLineController _ownedController;
  late KLineController _controller;
  final ScrollController _scrollController = ScrollController();

  /// 缩放开始时记录基准值，用于围绕焦点计算新的滚动偏移。
  double _baseScale = 1;
  double _scaleStartLocalFocalX = 0;
  double _scaleStartContentFocalX = 0;

  /// 最近一次完整图表上下文，用于滚动通知回调拿到最新布局信息。
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
        // 第一次创建 context 时 layoutNodes 为空，用于让 delegate 提前计算节点。
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
        // 第二次创建 context 时带上已计算好的布局节点，后续绘制和交互复用。
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
                // 固定层：绘制不随横向滚动移动的网格、坐标轴等内容。
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
                // 滚动层：绘制蜡烛、指标线等随内容宽度横向滚动的图层。
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
                // 覆盖层和选中层由 delegate 生成，适合放置水印、按钮、详情面板等 Widget。
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
    // 保证最后一根蜡烛完整显示，避免右侧蜡烛体被滚动内容宽度截断。
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

    // 只把用户主动拖动产生的滚动通知交给 delegate，避免外部 jumpTo 造成重复回调。
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
    // 根据手势横坐标查找最近的布局节点，保证十字线吸附到对应 K 线中心。
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
