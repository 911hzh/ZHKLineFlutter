import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_model_adapter.dart';
import 'package:example/module/usecase/pages/custom_page/custom_live_update_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kline_flutter/kline_flutter.dart';

import 'custom_demo_copy.dart';

class CustomLiveUpdatePage extends StatefulWidget {
  const CustomLiveUpdatePage({super.key});

  static const routeName = '/kline/custom/live-update';

  @override
  State<CustomLiveUpdatePage> createState() => _CustomLiveUpdatePageState();
}

class _CustomLiveUpdatePageState extends State<CustomLiveUpdatePage> {
  static const _copy = CustomDemoCopy(
    title: '数据更新后主动滚动',
    description: '业务层先决定数据插到头部还是尾部，更新完数据后，再主动调用 controller 的滚动方法把目标内容滚进可见区域。',
    extensionPoint: 'KLineController.scrollToLatest / scrollToIndex',
    scenario: '适合 socket 推送最新 K 线、补更多旧数据，或整窗替换后回到指定可见区域。',
  );

  final _controller = KLineController(
    initialFollowLatest: true,
    initialIndicators: const ['volume', 'ma'],
  );
  late final CustomLiveUpdateCubit _cubit;
  var _handledScrollRevision = 0;

  @override
  void initState() {
    super.initState();
    _cubit = CustomLiveUpdateCubit(klineStore: getIt<KlineStore>())..start();
    _controller.addListener(_syncFollowingLatestFromController);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFollowingLatestFromController);
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(_copy.title)),
      body: SafeArea(
        child: BlocConsumer<CustomLiveUpdateCubit, CustomLiveUpdateState>(
          bloc: _cubit,
          listener: (context, state) => _handleScrollAction(state),
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _Header(copy: _copy),
                const SizedBox(height: 12),
                _StatusCard(
                  controller: _controller,
                  count: state.candles.length,
                  autoUpdateCount: state.autoUpdateCount,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('跟随最新数据'),
                  subtitle: const Text('开启后，timer 推送新 K 线时自动保持最新一根可见。'),
                  value: state.isFollowingLatest,
                  onChanged: (value) {
                    _controller.setFollowingLatest(value);
                    _cubit.setFollowingLatest(value);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: state.candles.isEmpty
                          ? null
                          : _cubit.prependLatest,
                      child: const Text('头部插入后看最新'),
                    ),
                    OutlinedButton(
                      onPressed: state.candles.isEmpty
                          ? null
                          : _cubit.appendOlder,
                      child: const Text('尾部插入后看最旧'),
                    ),
                    OutlinedButton(
                      onPressed: state.sourceCandles.isEmpty
                          ? null
                          : _cubit.replaceWindow,
                      child: const Text('整窗替换后回左侧'),
                    ),
                    OutlinedButton(
                      onPressed: _controller.scrollToLatest,
                      child: const Text('手动回到最新'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '初始数据复用示例应用的真实 K 线数据；timer 每 3 秒模拟一次 socket 最新 K 线。页面自己更新数据，再主动调用一次滚动请求。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _buildChart(state),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleScrollAction(CustomLiveUpdateState state) {
    if (state.scrollRevision == _handledScrollRevision) return;
    _handledScrollRevision = state.scrollRevision;
    // cubit 先产出新列表，再由页面把“滚到哪里”翻译成 controller 调用。
    switch (state.scrollAction) {
      case CustomLiveScrollAction.latest:
        _controller.scrollToLatest();
        break;
      case CustomLiveScrollAction.oldest:
        _controller.scrollToIndex(
          state.candles.length - 1,
          alignment: KLineScrollAlignment.right,
        );
        break;
      case CustomLiveScrollAction.home:
        _controller.scrollToIndex(0, alignment: KLineScrollAlignment.left);
        break;
      case CustomLiveScrollAction.none:
        break;
    }
  }

  void _syncFollowingLatestFromController() {
    // 用户手动拖动会让 controller 关闭跟随，这里把开关状态同步回 demo 业务层。
    if (_cubit.state.isFollowingLatest == _controller.isFollowingLatest) return;
    _cubit.setFollowingLatest(_controller.isFollowingLatest);
  }

  Widget _buildChart(CustomLiveUpdateState state) {
    if (state.isLoading && state.candles.isEmpty) {
      return const SizedBox(
        height: 520,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null && state.candles.isEmpty) {
      return SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: ${state.error}'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _cubit.retry, child: const Text('重试')),
          ],
        ),
      );
    }
    if (state.candles.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('暂无数据')));
    }

    return KLineWidget<KLineModel>(
      controller: _controller,
      dataSource: state.candles,
      adapter: const CustomKLineModelAdapter(),
      isLoading: state.isLoading,
      error: state.error,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.controller,
    required this.count,
    required this.autoUpdateCount,
  });

  final KLineController controller;
  final int count;
  final int autoUpdateCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'items $count | auto $autoUpdateCount | followLatest ${controller.isFollowingLatest} | offset ${controller.scrollOffset.toStringAsFixed(1)} | visible ${controller.visibleRange ?? '-'}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.copy});

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
            Text(
              '扩展点: ${copy.extensionPoint}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4D5966)),
            ),
            const SizedBox(height: 6),
            Text(
              '适用场景: ${copy.scenario}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4D5966)),
            ),
          ],
        ),
      ),
    );
  }
}
