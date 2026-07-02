import 'package:flutter/material.dart';
import 'package:kline_flutter/src/deepchart/adapter/deep_chart_data_adapter.dart';
import 'package:kline_flutter/src/deepchart/delegate/deep_chart_delegate.dart';
import 'package:kline_flutter/src/deepchart/model/deep_depth_entry.dart';
import 'package:kline_flutter/src/deepchart/theme/deep_chart_theme.dart';
import 'package:kline_flutter/src/deepchart/u_default_impl/deep_chart_default_delegate.dart';

/// 深度图组件。
///
/// 组件接收买盘和卖盘数据，通过 [DeepChartDataAdapter] 读取价格与数量，
/// 再交给 [DeepChartDelegate] 完成布局、绘制和覆盖层构建。
class DeepChart<T> extends StatelessWidget {
  /// 创建深度图组件。
  const DeepChart({
    super.key,
    required this.bids,
    required this.asks,
    required this.adapter,
    this.delegate,
    this.theme = const DeepChartTheme(),
    this.layout = const DeepChartLayoutConfig(),
    this.loadingBuilder,
    this.emptyBuilder,
    this.isLoading = false,
  });

  /// 买盘数据，通常按价格降序排列。
  final List<T> bids;

  /// 卖盘数据，通常按价格升序排列。
  final List<T> asks;

  /// 业务数据到深度图价格/数量字段的适配器。
  final DeepChartDataAdapter<T> adapter;

  /// 自定义绘制代理。
  ///
  /// 为空时使用 [DeepChartDefaultDelegate]。
  final DeepChartDelegate<T>? delegate;

  /// 默认 UI 主题。
  final DeepChartTheme theme;

  /// 默认 UI 布局配置。
  final DeepChartLayoutConfig layout;

  /// 自定义加载占位。
  final WidgetBuilder? loadingBuilder;

  /// 自定义空数据占位。
  final WidgetBuilder? emptyBuilder;

  /// 是否显示加载占位。
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final defaultHeight = layout.mainHeight + layout.bottomHeight;
    if (isLoading) {
      return SizedBox(
        height: defaultHeight,
        child:
            loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator()),
      );
    }
    if (bids.isEmpty && asks.isEmpty) {
      return SizedBox(
        height: defaultHeight,
        child:
            emptyBuilder?.call(context) ?? const Center(child: Text('暂无深度数据')),
      );
    }

    final effectiveDelegate =
        delegate ?? DeepChartDefaultDelegate<T>(watermark: '火币');
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        final baseContext = DeepChartContext<T>(
          bids: bids,
          asks: asks,
          adapter: adapter,
          theme: theme,
          layout: layout,
          viewportSize: Size(width, defaultHeight),
          nodes: const DeepDepthNodes(bids: [], asks: []),
        );
        final nodes = effectiveDelegate.getLayoutNodes(baseContext);
        final chartContext = DeepChartContext<T>(
          bids: bids,
          asks: asks,
          adapter: adapter,
          theme: theme,
          layout: layout,
          viewportSize: Size(width, defaultHeight),
          nodes: nodes,
        );
        final height = effectiveDelegate.chartHeight(chartContext);
        final overlay = effectiveDelegate.buildOverlayView(
          context,
          chartContext,
        );
        return ColoredBox(
          color: theme.backgroundColor,
          child: ClipRect(
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DeepChartPainter<T>(
                        context: chartContext,
                        delegate: effectiveDelegate,
                      ),
                    ),
                  ),
                  if (overlay != null) overlay,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 深度图 painter。
///
/// 这里只负责把 canvas 调度给 delegate，具体绘制逻辑由 delegate 决定。
class _DeepChartPainter<T> extends CustomPainter {
  const _DeepChartPainter({required this.context, required this.delegate});

  final DeepChartContext<T> context;
  final DeepChartDelegate<T> delegate;

  @override
  void paint(Canvas canvas, Size size) {
    delegate.drawGrid(canvas, size, context);
    delegate.drawChart(canvas, size, context);
  }

  @override
  bool shouldRepaint(covariant _DeepChartPainter<T> oldDelegate) {
    return oldDelegate.context != context || oldDelegate.delegate != delegate;
  }
}
