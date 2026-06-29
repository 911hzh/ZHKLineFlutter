import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

enum _StateDemoMode { normal, loading, empty, error }

class CustomStateBuilderPage extends StatefulWidget {
  const CustomStateBuilderPage({super.key});

  static const routeName = '/kline/custom/state-builders';

  @override
  State<CustomStateBuilderPage> createState() => _CustomStateBuilderPageState();
}

class _CustomStateBuilderPageState extends State<CustomStateBuilderPage> {
  var _mode = _StateDemoMode.normal;

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '自定义加载与错误状态',
        description:
            'KLineWidget 暴露 loadingBuilder、emptyBuilder、errorBuilder 和 onRetry，不需要业务方包一层状态占位。',
        extensionPoint:
            'KLineWidget.loadingBuilder / emptyBuilder / errorBuilder / onRetry',
        scenario: '适合接入统一 Design System、骨架屏、空态插画、错误重试按钮和弱网提示。',
      ),
      passPlaceholderStateToWidget: true,
      controlsBuilder: (context, controller, state, actions) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _modeButton('真实数据', _StateDemoMode.normal),
            _modeButton('Loading', _StateDemoMode.loading),
            _modeButton('Empty', _StateDemoMode.empty),
            _modeButton('Error', _StateDemoMode.error),
          ],
        );
      },
      chartBuilder: (context, state, controller, adapter, actions, onScroll) {
        final dataSource = _dataSourceForMode(state.data);
        return KLineWidget<KLineModel>(
          controller: controller,
          dataSource: dataSource,
          adapter: adapter,
          layout: const KLineLayoutConfig(mainChartHeight: 320),
          isLoading:
              _mode == _StateDemoMode.loading ||
              (_mode == _StateDemoMode.normal && state.isLoading),
          error: _mode == _StateDemoMode.error
              ? StateError('模拟网络错误')
              : state.error,
          onRetry: () {
            setState(() => _mode = _StateDemoMode.normal);
            actions.retry();
          },
          onScroll: onScroll,
          loadingBuilder: (_) => const _StateCard(
            title: '正在加载行情',
            message: '这里可以替换为骨架屏、品牌 loading 或行情占位动画。',
          ),
          emptyBuilder: (_) => const _StateCard(
            title: '暂无 K 线数据',
            message: '这里可以放空态插画、引导文案或切换周期按钮。',
          ),
          errorBuilder: (_, error, retry) => _StateCard(
            title: '加载失败',
            message: '$error',
            actionText: '重新加载',
            onAction: retry,
          ),
        );
      },
    );
  }

  List<KLineModel> _dataSourceForMode(List<KLineModel> source) {
    return switch (_mode) {
      _StateDemoMode.normal => source,
      _ => const [],
    };
  }

  Widget _modeButton(String label, _StateDemoMode mode) {
    final selected = _mode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _mode = mode),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8E3FF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton(onPressed: onAction, child: Text(actionText!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
