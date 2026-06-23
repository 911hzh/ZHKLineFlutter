// ignore_for_file: file_names

import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:k_line_flutter/k_line_flutter.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';

part 'kline_model_adapter.dart';
part 'kline_demo_widgets.dart';

/// K 线 Demo 页面入口，只负责装配 Bloc、图表控制器和页面布局。
///
/// 数据加载、缓存和错误状态由 [KLineDemoCubit] / [KlineStore] 负责，
/// 默认绘制和交互 UI 由 package 的 [KLineWidget] 负责。
class KLineDemoPage extends StatefulWidget {
  const KLineDemoPage({super.key});

  @override
  State<KLineDemoPage> createState() => _KLineDemoPageState();
}

/// 页面状态只保留图表交互控制器，避免把业务数据状态放回 Widget 内。
class _KLineDemoPageState extends State<KLineDemoPage> {
  static const _chartLayout = KLineLayoutConfig(
    candleWidth: 8.5,
    candleSpacing: 2,
    mainChartHeight: 342,
    secondaryPaneHeight: 70,
    indicatorSelectorHeight: 30,
    gridHorizontalCount: 5,
    gridVerticalCount: 6,
    minScale: 0.6,
    maxScale: 3,
  );

  final _controller = KLineController(initialIndicators: const ['volume']);
  static const _edgeLoadThreshold = 20.0;
  var _shouldScrollToInitialLatest = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPeriod(BuildContext context, KLinePeriod period) {
    _shouldScrollToInitialLatest = true;
    _controller
      ..clearSelection()
      ..setScrollOffset(0);
    context.read<KLineDemoCubit>().selectPeriod(period);
  }

  void _handleStateChange(KLineDemoState state) {
    if (!_shouldScrollToInitialLatest || state.data.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToLatest();
      if (!state.isLoading) {
        _shouldScrollToInitialLatest = false;
      }
    });
  }

  void _scrollToLatest() {
    _controller.setScrollOffset(0);
  }

  void _handleUserScroll(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
    KLineScrollMetrics metrics,
  ) {
    final reachedOlder = metrics.extentAfter <= _edgeLoadThreshold;
    // LoggerFactory.current
    //     .getLogger(['KLineDemoPage'])
    //     .info(
    //       'reachedOlder: $reachedOlder, metrics.scrollDelta: ${metrics.scrollDelta}',
    //     );
    if (reachedOlder && metrics.scrollDelta > 0) {
      context.read<KLineDemoCubit>().loadMore();
    }
  }

  /// 示例页右侧放大按钮：以当前屏幕中心作为缩放焦点。
  void _zoomFromButton() {
    final nextScale = _controller.scale >= 3 ? 0.6 : _controller.scale * 1.2;
    _controller.setScaleAroundFocalPoint(
      scale: nextScale,
      baseScale: _controller.scale,
      localFocalX: MediaQuery.sizeOf(context).width / 2,
      contentFocalX:
          _controller.scrollOffset + MediaQuery.sizeOf(context).width / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KLineDemoCubit(klineStore: getIt<KlineStore>())..start(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocConsumer<KLineDemoCubit, KLineDemoState>(
            listener: (context, state) => _handleStateChange(state),
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _TopBar(onClose: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: 10),
                    _PeriodSelector(
                      selectedPeriod: state.selectedPeriod,
                      onSelected: (period) => _selectPeriod(context, period),
                      onZoom: _zoomFromButton,
                    ),
                    const SizedBox(height: 10),
                    _buildChart(context, state),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 根据 Cubit 状态构建图表区域，并在后台刷新时保留缓存图表。
  Widget _buildChart(BuildContext context, KLineDemoState state) {
    if (state.isLoading && state.data.isEmpty) {
      return const SizedBox(
        height: 412,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.data.isEmpty) {
      return SizedBox(
        height: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<KLineDemoCubit>().retry(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.data.isEmpty) {
      return const SizedBox(height: 240, child: Center(child: Text('暂无数据')));
    }

    return Stack(
      children: [
        KLineWidget<KLineModel>(
          controller: _controller,
          dataSource: state.data,
          adapter: const _KLineModelAdapter(),
          onScroll: (chartContext, metrics) {
            _handleUserScroll(context, chartContext, metrics);
          },
          layout: _chartLayout,
          isLoading: state.isLoading,
          error: state.error,
        ),
      ],
    );
  }
}
