import 'package:flutter/material.dart';

import '../controller/kline_controller.dart';
import '../delegate/kline_chart_delegate.dart';
import '../theme/kline_theme.dart';
import '../widgets/kline_chart.dart';
import 'kline_data_adapter.dart';
import 'kline_default_delegate.dart';

/// 默认 K 线 UI 组件。
///
/// 适合快速接入完整 K 线图。业务方只需要传入数据数组和 [KLineDataAdapter]；
/// 如果需要深度定制，也可以通过 [delegate] 传入自己的 [KLineChartDelegate]。
class KLineWidget<T> extends StatefulWidget {
  /// 创建默认 K 线组件。
  const KLineWidget({
    super.key,
    required this.dataSource,
    required this.adapter,
    this.controller,
    this.delegate,
    this.theme = const KLineTheme(),
    this.layout = const KLineLayoutConfig(),
    this.behavior = const KLineBehaviorConfig(),
    this.initialIndicators,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onScroll,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  });

  /// 当前需要绘制的数据数组。
  final List<T> dataSource;

  /// 业务模型适配器，默认 delegate 通过它读取 OHLCV、日期和指标值。
  final KLineDataAdapter<T> adapter;

  /// 外部传入的图表控制器；不传时组件内部会创建并持有一个控制器。
  final KLineController? controller;

  /// 自定义 delegate；不传时使用默认 delegate。
  final KLineChartDelegate<T>? delegate;

  /// 图表主题配置。
  final KLineTheme theme;

  /// 图表布局配置。
  final KLineLayoutConfig layout;

  /// 图表交互配置。
  final KLineBehaviorConfig behavior;

  /// 内部控制器创建时使用的初始指标集合。
  final Iterable<String>? initialIndicators;

  /// 是否正在加载。
  final bool isLoading;

  /// 当前错误；有缓存数据时显示顶部错误提示，没有数据时显示错误占位。
  final Object? error;

  /// 默认错误占位中的重试回调。
  final VoidCallback? onRetry;

  /// 用户滚动回调，可用于加载更多或刷新最新数据。
  final void Function(KLineChartContext<T> context, KLineScrollMetrics metrics)?
  onScroll;

  /// 首次加载时的自定义 loading UI。
  final WidgetBuilder? loadingBuilder;

  /// 空数据占位 UI。
  final WidgetBuilder? emptyBuilder;

  /// 错误占位 UI。
  final Widget Function(
    BuildContext context,
    Object error,
    VoidCallback? retry,
  )?
  errorBuilder;

  @override
  State<KLineWidget<T>> createState() => _KLineWidgetState<T>();
}

class _KLineWidgetState<T> extends State<KLineWidget<T>> {
  late KLineController _ownedController;
  late KLineController _controller;

  /// 初始化内部或外部控制器。
  @override
  void initState() {
    super.initState();
    _ownedController = _createOwnedController();
    _controller = widget.controller ?? _ownedController;
  }

  /// 外部 controller 变化时同步当前使用的控制器。
  @override
  void didUpdateWidget(covariant KLineWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller = widget.controller ?? _ownedController;
    }
  }

  /// 释放内部创建的控制器。
  @override
  void dispose() {
    _ownedController.dispose();
    super.dispose();
  }

  /// 根据加载、错误、空数据和正常数据状态构建默认 UI。
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.dataSource.isEmpty) {
      return SizedBox(
        height: _estimatedHeight(),
        child:
            widget.loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null && widget.dataSource.isEmpty) {
      return SizedBox(
        height: _estimatedHeight(),
        child: _buildError(context, widget.error!),
      );
    }

    if (widget.dataSource.isEmpty) {
      return SizedBox(
        height: _estimatedHeight(),
        child:
            widget.emptyBuilder?.call(context) ??
            const Center(child: Text('暂无数据')),
      );
    }

    return Stack(
      children: [
        KLineChart<T>(
          controller: _controller,
          dataSource: widget.dataSource,
          delegate:
              widget.delegate ??
              KLineDefaultDelegateImpl<T>(
                adapter: widget.adapter,
                onScroll: widget.onScroll,
              ),
          theme: widget.theme,
          layout: widget.layout,
          behavior: widget.behavior,
        ),
        if (widget.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (widget.error != null)
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border.all(color: Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  '刷新失败: ${widget.error}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 创建内部控制器，并注入默认或外部指定的初始指标。
  KLineController _createOwnedController() {
    return KLineController(
      initialIndicators:
          widget.initialIndicators ?? [KLineDefaultIndicatorType.volume.name],
    );
  }

  /// 估算占位状态下的组件高度。
  double _estimatedHeight() {
    return widget.layout.chartHeight(
      secondaryPaneCount: 1,
      includeSelector: true,
    );
  }

  /// 构建默认错误占位。
  Widget _buildError(BuildContext context, Object error) {
    final builder = widget.errorBuilder;
    if (builder != null) {
      return builder(context, error, widget.onRetry);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('加载失败: $error'),
        if (widget.onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: widget.onRetry, child: const Text('重试')),
        ],
      ],
    );
  }
}
