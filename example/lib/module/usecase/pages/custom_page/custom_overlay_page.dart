import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

class CustomOverlayPage extends StatelessWidget {
  const CustomOverlayPage({super.key});

  static const routeName = '/kline/custom/overlay';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '自定义覆盖层 UI',
        description:
            '覆盖 buildOverlayView 可以替换默认指标标签、底部指标选择器，或叠加品牌水印、快捷操作和行情提示。',
        extensionPoint: 'KLineChartDelegate.buildOverlayView',
        scenario: '适合做交易所行情页的自定义顶部指标条、底部工具栏、浮动按钮和状态提示。',
      ),
      initialIndicators: const ['ma', 'volume'],
      delegateBuilder: (adapter, onScroll) {
        return _CustomOverlayDelegate(adapter: adapter, onScroll: onScroll);
      },
    );
  }
}

class _CustomOverlayDelegate extends KLineDefaultDelegateImpl<KLineModel> {
  const _CustomOverlayDelegate({required super.adapter, super.onScroll});
  @override
  double chartHeight(KLineChartContext<KLineModel> context) {
    final height = super.chartHeight(context);
    return height + 50;
  }

  @override
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
  ) {
    final selected =
        chartContext.selectedNode?.item ??
        (chartContext.layoutNodes.isEmpty
            ? null
            : chartContext.layoutNodes.first.item);
    return Stack(
      children: [
        if (selected != null)
          _TopIndicatorPanel(
            context: chartContext,
            item: selected,
            adapter: adapter,
          ),
        Positioned(
          right: 12,
          top: 12,
          child: _RangeBadge(range: chartContext.visibleRange),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 6,
          child: _FloatingIndicatorBar(context: chartContext),
        ),
      ],
    );
  }
}

class _TopIndicatorPanel extends StatelessWidget {
  const _TopIndicatorPanel({
    required this.context,
    required this.item,
    required this.adapter,
  });

  final KLineChartContext<KLineModel> context;
  final KLineModel item;
  final KLineDataAdapter<KLineModel> adapter;

  @override
  Widget build(BuildContext buildContext) {
    final activeEntries = <KLineIndicatorEntry>[
      for (final type in KLineDefaultIndicatorType.mainTypes)
        if (context.controller.activeIndicatorIds.contains(type.name))
          ...adapter.mainIndicatorEntries(item, type),
    ].where((entry) => entry.value != null).take(3).toList();

    return Positioned(
      left: 12,
      top: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EBF0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '自定义指标条',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              for (final entry in activeEntries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${entry.label} ${entry.value!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.theme.indicatorColorAt(entry.colorIndex),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeBadge extends StatelessWidget {
  const _RangeBadge({required this.range});

  final KLineVisibleRange range;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'visible ${range.start}-${range.end}',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}

class _FloatingIndicatorBar extends StatelessWidget {
  const _FloatingIndicatorBar({required this.context});

  final KLineChartContext<KLineModel> context;

  @override
  Widget build(BuildContext buildContext) {
    return AnimatedBuilder(
      animation: context.controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                for (final type in KLineDefaultIndicatorType.values)
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          this.context.controller.toggleIndicator(type.name),
                      child: Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              this.context.controller.activeIndicatorIds
                                  .contains(type.name)
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
