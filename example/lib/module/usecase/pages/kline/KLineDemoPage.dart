// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';
import 'package:k_line_flutter/k_line_flutter.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorsModel.dart';

part 'kline_demo_geometry.dart';
part 'kline_demo_widgets.dart';
part 'kline_demo_data_source.dart';
part 'kline_demo_delegate.dart';
part 'kline_demo_labels.dart';
part 'kline_demo_extractors.dart';

/// K 线 Demo 页面入口，只负责装配 Bloc、图表控制器和页面布局。
///
/// 数据加载、缓存和错误状态由 [KLineDemoCubit] / [KlineStore] 负责，
/// 具体绘制逻辑拆分到 `kline_demo_delegate.dart`。
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

  void _handleUserScroll(BuildContext context, KLineChartContext<KLineModel> chartContext, KLineScrollMetrics metrics) {
    final reachedOlder = metrics.extentAfter <= _edgeLoadThreshold;
    LoggerFactory.current
        .getLogger(['KLineDemoPage'])
        .info('reachedOlder: $reachedOlder, metrics.scrollDelta: ${metrics.scrollDelta}');
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
      contentFocalX: _controller.scrollOffset + MediaQuery.sizeOf(context).width / 2,
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
      return const SizedBox(height: 412, child: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null && state.data.isEmpty) {
      return SizedBox(
        height: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.read<KLineDemoCubit>().retry(), child: const Text('重试')),
          ],
        ),
      );
    }

    if (state.data.isEmpty) {
      return const SizedBox(height: 240, child: Center(child: Text('暂无数据')));
    }

    return Stack(
      children: [
        KLineChart<KLineModel>(
          controller: _controller,
          dataSource: _KLineDemoDataSource(state.data),
          delegate: _KLineDemoDelegate(
            onScroll: (chartContext, metrics) {
              _handleUserScroll(context, chartContext, metrics);
            },
          ),
          layout: _chartLayout,
        ),
        if (state.isLoading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
        if (state.error != null)
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
                child: Text('刷新失败: ${state.error}', style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
      ],
    );
  }
}
