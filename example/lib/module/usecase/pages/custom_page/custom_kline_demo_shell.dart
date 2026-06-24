import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_model_adapter.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kline_flutter/kline_flutter.dart';

typedef CustomKLineDelegateBuilder =
    KLineChartDelegate<KLineModel> Function(
      KLineDataAdapter<KLineModel> adapter,
      void Function(
        KLineChartContext<KLineModel> context,
        KLineScrollMetrics metrics,
      )
      onScroll,
    );

typedef CustomKLineControlsBuilder =
    Widget Function(
      BuildContext context,
      KLineController controller,
      KLineDemoState state,
      CustomKLineDemoActions actions,
    );

typedef CustomKLineChartBuilder =
    Widget Function(
      BuildContext context,
      KLineDemoState state,
      KLineController controller,
      KLineDataAdapter<KLineModel> adapter,
      CustomKLineDemoActions actions,
      void Function(
        KLineChartContext<KLineModel> context,
        KLineScrollMetrics metrics,
      )
      onScroll,
    );

class CustomKLineDemoActions {
  const CustomKLineDemoActions({required this.retry, required this.loadMore});

  final VoidCallback retry;
  final VoidCallback loadMore;
}

class CustomKLineDemoShell extends StatefulWidget {
  const CustomKLineDemoShell({
    super.key,
    required this.copy,
    this.adapter = const CustomKLineModelAdapter(),
    this.theme = const KLineTheme(),
    this.layout = const KLineLayoutConfig(),
    this.behavior = const KLineBehaviorConfig(),
    this.initialIndicators = const ['volume'],
    this.delegateBuilder,
    this.controlsBuilder,
    this.chartBuilder,
    this.passPlaceholderStateToWidget = false,
    this.backgroundColor = Colors.white,
  });

  final CustomDemoCopy copy;
  final KLineDataAdapter<KLineModel> adapter;
  final KLineTheme theme;
  final KLineLayoutConfig layout;
  final KLineBehaviorConfig behavior;
  final Iterable<String> initialIndicators;
  final CustomKLineDelegateBuilder? delegateBuilder;
  final CustomKLineControlsBuilder? controlsBuilder;
  final CustomKLineChartBuilder? chartBuilder;
  final bool passPlaceholderStateToWidget;
  final Color backgroundColor;

  @override
  State<CustomKLineDemoShell> createState() => _CustomKLineDemoShellState();
}

class _CustomKLineDemoShellState extends State<CustomKLineDemoShell> {
  static const _edgeLoadThreshold = 20.0;

  late final KLineController _controller;
  late final KLineDemoCubit _cubit;
  late final CustomKLineDemoActions _actions;
  var _shouldScrollToInitialLatest = true;

  @override
  void initState() {
    super.initState();
    _controller = KLineController(initialIndicators: widget.initialIndicators);
    _cubit = KLineDemoCubit(klineStore: getIt<KlineStore>())..start();
    _actions = CustomKLineDemoActions(
      retry: () {
        _cubit.retry();
      },
      loadMore: () {
        _cubit.loadMore();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(title: Text(widget.copy.title)),
      body: SafeArea(
        child: BlocConsumer<KLineDemoCubit, KLineDemoState>(
          bloc: _cubit,
          listener: (context, state) => _handleStateChange(state),
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _CustomDemoHeader(copy: widget.copy),
                const SizedBox(height: 12),
                if (widget.controlsBuilder != null) ...[
                  widget.controlsBuilder!(
                    context,
                    _controller,
                    state,
                    _actions,
                  ),
                  const SizedBox(height: 12),
                ],
                _buildChart(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleStateChange(KLineDemoState state) {
    if (!_shouldScrollToInitialLatest || state.data.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.setScrollOffset(0);
      if (!state.isLoading) {
        _shouldScrollToInitialLatest = false;
      }
    });
  }

  Widget _buildChart(BuildContext context, KLineDemoState state) {
    if (widget.chartBuilder != null) {
      return widget.chartBuilder!(
        context,
        state,
        _controller,
        widget.adapter,
        _actions,
        _handleUserScroll,
      );
    }

    if (!widget.passPlaceholderStateToWidget) {
      if (state.isLoading && state.data.isEmpty) {
        return SizedBox(
          height: widget.layout.chartHeight(secondaryPaneCount: 1),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (state.error != null && state.data.isEmpty) {
        return _ShellMessage(
          height: 220,
          message: '加载失败: ${state.error}',
          actionText: '重试',
          onAction: _actions.retry,
        );
      }
      if (state.data.isEmpty) {
        return const _ShellMessage(height: 220, message: '暂无数据');
      }
    }

    final delegate = widget.delegateBuilder?.call(
      widget.adapter,
      _handleUserScroll,
    );
    return KLineWidget<KLineModel>(
      controller: _controller,
      dataSource: state.data,
      adapter: widget.adapter,
      delegate: delegate,
      theme: widget.theme,
      layout: widget.layout,
      behavior: widget.behavior,
      isLoading: state.isLoading,
      error: state.error,
      onRetry: _actions.retry,
      onScroll: delegate == null ? _handleUserScroll : null,
    );
  }

  void _handleUserScroll(
    KLineChartContext<KLineModel> chartContext,
    KLineScrollMetrics metrics,
  ) {
    final reachedOlder = metrics.extentAfter <= _edgeLoadThreshold;
    if (reachedOlder && metrics.scrollDelta > 0) {
      _actions.loadMore();
    }
  }
}

class _CustomDemoHeader extends StatelessWidget {
  const _CustomDemoHeader({required this.copy});

  final CustomDemoCopy copy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 10),
            _InfoLine(label: '扩展点', value: copy.extensionPoint),
            const SizedBox(height: 6),
            _InfoLine(label: '适用场景', value: copy.scenario),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF4D5966),
        height: 1.35,
      ),
    );
  }
}

class _ShellMessage extends StatelessWidget {
  const _ShellMessage({
    required this.height,
    required this.message,
    this.actionText,
    this.onAction,
  });

  final double height;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
