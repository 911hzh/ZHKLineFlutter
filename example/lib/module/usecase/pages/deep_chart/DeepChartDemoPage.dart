import 'package:example/base/api/KlineApi.dart';
import 'package:example/base/api/model/depth/DepthResponse.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/deep_chart/DeepChartDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kline_flutter/kline_flutter.dart';

/// 深度图示例页面。
///
/// 页面通过 [DeepChartDemoCubit] 请求火币 `/market/depth` REST 快照，
/// 再把买盘和卖盘数据交给 package 的 [DeepChart] 展示。
class DeepChartDemoPage extends StatelessWidget {
  /// 创建深度图示例页面。
  const DeepChartDemoPage({super.key});

  /// 路由名称，用于 example 首页和路由表注册。
  static const routeName = '/kline/deep-chart';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeepChartDemoCubit(api: getIt<KlineApi>())..start(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('深度图 Demo')),
        body: SafeArea(
          child: BlocBuilder<DeepChartDemoCubit, DeepChartDemoState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  const _IntroCard(),
                  const SizedBox(height: 12),
                  _buildChart(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 根据当前状态构建深度图区域。
  ///
  /// 首次加载失败且没有缓存数据时展示错误占位；否则展示 [DeepChart]，
  /// 让图表在后台刷新时仍保留已有盘口快照。
  Widget _buildChart(BuildContext context, DeepChartDemoState state) {
    if (state.error != null && state.bids.isEmpty && state.asks.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: ${state.error}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<DeepChartDemoCubit>().retry(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: DeepChart<DepthLevel>(
        bids: state.bids,
        asks: state.asks,
        adapter: const _DepthLevelAdapter(),
        isLoading: state.isLoading && state.bids.isEmpty && state.asks.isEmpty,
        layout: const DeepChartLayoutConfig(
          mainHeight: 200,
          contentPadding: EdgeInsets.fromLTRB(10, 10, 20, 10),
        ),
        theme: const DeepChartTheme(
          bidColor: Color(0xFF18B77A),
          askColor: Color(0xFFF0526B),
          gridLineColor: Color(0xFFEDEDED),
          textColor: Color(0xFF9A9A9A),
        ),
      ),
    );
  }
}

/// 深度图示例说明卡片。
class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E8EB)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'REST /market/depth 深度快照。买盘和卖盘按价格档位累加数量，默认 UI 使用左右面积图展示盘口深度。',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
      ),
    );
  }
}

/// 将火币深度响应模型适配给 package 的深度图组件。
///
/// `DepthLevel` 已经包含 `price` 和 `size`，这里仅把字段透传给
/// [DeepChartDataAdapter]。
class _DepthLevelAdapter extends DeepChartDataAdapter<DepthLevel> {
  const _DepthLevelAdapter();

  /// 返回盘口档位价格。
  @override
  double price(DepthLevel item) => item.price;

  /// 返回盘口档位数量。
  @override
  double size(DepthLevel item) => item.size;
}
