import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

class CustomControllerPage extends StatelessWidget {
  const CustomControllerPage({super.key});

  static const routeName = '/kline/custom/controller';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '外部控制图表状态',
        description: 'KLineController 暴露缩放、滚动、选中项、可见区和指标状态，页面可以像控制普通组件一样控制图表。',
        extensionPoint: 'KLineController',
        scenario: '适合做工具栏按钮、同步多个图表、快捷切换指标、跳转到指定 K 线或外部联动选中。',
      ),
      initialIndicators: const ['volume'],
      controlsBuilder: (context, controller, state, actions) {
        return _ControllerPanel(controller: controller);
      },
    );
  }
}

class _ControllerPanel extends StatelessWidget {
  const _ControllerPanel({required this.controller});

  final KLineController controller;

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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'scale ${controller.scale.toStringAsFixed(2)} | offset ${controller.scrollOffset.toStringAsFixed(0)} | visible ${controller.visibleRange ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => controller.setScale(
                        (controller.scale * 1.2).clamp(0.5, 3).toDouble(),
                      ),
                      child: const Text('放大'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.setScale(
                        (controller.scale / 1.2).clamp(0.5, 3).toDouble(),
                      ),
                      child: const Text('缩小'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.setScrollOffset(
                        controller.scrollOffset + 120,
                      ),
                      child: const Text('向历史滚动'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.setScrollOffset(0),
                      child: const Text('回到最新'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.toggleIndicator(
                        KLineDefaultIndicatorType.ma.name,
                      ),
                      child: const Text('切换 MA'),
                    ),
                    OutlinedButton(
                      onPressed: () => controller.selectIndex(
                        controller.visibleRange?.start,
                      ),
                      child: const Text('选中首个可见点'),
                    ),
                    TextButton(
                      onPressed: () {
                        controller
                          ..clearSelection()
                          ..setActiveIndicators([
                            KLineDefaultIndicatorType.volume.name,
                          ])
                          ..setScale(1)
                          ..setScrollOffset(0);
                      },
                      child: const Text('重置'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
