import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomSelectionViewPage extends StatelessWidget {
  const CustomSelectionViewPage({super.key});

  static const routeName = '/kline/custom/selection-view';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '自定义长按详情 UI',
        description:
            '覆盖 buildSelectionView 可以完全替换默认详情面板，按业务需要展示价格、涨跌幅、成交量、操作按钮等内容。',
        extensionPoint: 'KLineChartDelegate.buildSelectionView',
        scenario: '适合交易详情浮层、移动端轻量卡片、PC 端 tooltip 或带快捷交易入口的行情详情。',
      ),
      delegateBuilder: (adapter, onScroll) {
        return _CustomSelectionDelegate(adapter: adapter, onScroll: onScroll);
      },
    );
  }
}

class _CustomSelectionDelegate extends KLineDefaultDelegateImpl<KLineModel> {
  const _CustomSelectionDelegate({required super.adapter, super.onScroll});

  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
    KLineLayoutNode<KLineModel> selectedNode,
  ) {
    final item = selectedNode.item;
    final touchX = chartContext.controller.selectionLocalPosition?.dx ?? 0;
    final showRight = touchX < chartContext.viewportSize.width / 2;
    return Positioned(
      left: showRight ? null : 12,
      right: showRight ? 12 : null,
      top: 18,
      child: _TradeDetailCard(item: item),
    );
  }
}

class _TradeDetailCard extends StatelessWidget {
  const _TradeDetailCard({required this.item});

  final KLineModel item;

  @override
  Widget build(BuildContext context) {
    final isRising = item.close >= item.open;
    final trendColor = isRising
        ? const Color(0xFFF14965)
        : const Color(0xFF00B066);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 176,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.dateString,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              Text(
                item.close.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: trendColor,
                ),
              ),
              const SizedBox(height: 6),
              _DetailRow(
                label: '开 / 高',
                value:
                    '${item.open.toStringAsFixed(2)} / ${item.high.toStringAsFixed(2)}',
              ),
              _DetailRow(
                label: '低 / 量',
                value:
                    '${item.low.toStringAsFixed(2)} / ${item.volume.toStringAsFixed(0)}',
              ),
              _DetailRow(
                label: '涨跌幅',
                value:
                    '${item.changeRate >= 0 ? '+' : ''}${(item.changeRate * 100).toStringAsFixed(2)}%',
                color: trendColor,
              ),
              const SizedBox(height: 8),
              const Text(
                '这里可以加入买入、卖出或提醒按钮',
                style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
