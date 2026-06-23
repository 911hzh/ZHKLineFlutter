import 'package:flutter/material.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

/// 默认底部指标选择器。
///
/// 点击指标按钮会通过 [KLineController.toggleIndicator] 切换主图或副图指标。
class KLineDefaultIndicatorSelector<T> extends StatelessWidget {
  /// 创建默认指标选择器。
  const KLineDefaultIndicatorSelector({super.key, required this.context});

  /// 当前图表上下文。
  final KLineChartContext<T> context;

  /// 构建指标选择栏。
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: this.context.controller,
      builder: (context, _) {
        return SizedBox(
          height: 30,
          child: ColoredBox(
            color: Colors.white,
            child: Row(
              children: [
                for (final type in KLineDefaultIndicatorType.mainTypes)
                  Expanded(child: _button(type)),
                Container(width: 1, height: 10, color: Colors.grey[400]),
                for (final type in KLineDefaultIndicatorType.secondaryTypes)
                  Expanded(child: _button(type)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建单个指标按钮。
  Widget _button(KLineDefaultIndicatorType type) {
    final selected = context.controller.activeIndicatorIds.contains(type.name);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.controller.toggleIndicator(type.name),
      child: Center(
        child: Text(
          type.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? Colors.black : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

/// 默认主图指标标签。
///
/// 展示当前选中或首个可见 K 线的主图指标值，例如 MA、EMA、BOLL。
class MainIndicatorLabels<T> extends StatelessWidget {
  /// 创建默认主图指标标签。
  const MainIndicatorLabels({
    required this.context,
    required this.selected,
    required this.adapter,
  });

  /// 当前图表上下文。
  final KLineChartContext<T> context;

  /// 当前用于展示指标值的数据项。
  final T selected;

  /// 数据适配器，用于读取指标展示项。
  final KLineDataAdapter<T> adapter;

  /// 构建主图指标标签区域。
  @override
  Widget build(BuildContext context) {
    final active = this.context.controller.activeIndicatorIds;
    return Positioned(
      left: 12,
      top: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final type in KLineDefaultIndicatorType.mainTypes)
            if (active.contains(type.name))
              _row(adapter.mainIndicatorEntries(selected, type)),
        ],
      ),
    );
  }

  /// 构建一行主图指标标签。
  Widget _row(List<KLineIndicatorEntry> values) {
    final children =
        values
            .where((value) => value.value != null)
            .map(
              (value) => Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: Text(
                  '${value.label}:${value.value!.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: context.theme.indicatorColorAt(value.colorIndex),
                    fontSize: 9,
                  ),
                ),
              ),
            )
            .toList();
    if (children.isEmpty) return const SizedBox.shrink();
    return Row(children: children);
  }
}

/// 默认副图指标标签。
///
/// 按副图顺序展示每个副图左上角的指标值。
class SecondaryIndicatorLabels<T> extends StatelessWidget {
  /// 创建默认副图指标标签。
  const SecondaryIndicatorLabels({
    required this.context,
    required this.selected,
    required this.adapter,
  });

  /// 当前图表上下文。
  final KLineChartContext<T> context;

  /// 当前用于展示指标值的数据项。
  final T selected;

  /// 数据适配器，用于读取指标展示项。
  final KLineDataAdapter<T> adapter;

  /// 构建副图指标标签集合。
  @override
  Widget build(BuildContext context) {
    final activeTypes =
        KLineDefaultIndicatorType.secondaryTypes
            .where(
              (type) => this.context.controller.activeIndicatorIds.contains(
                type.name,
              ),
            )
            .toList();
    return Stack(
      children: [
        for (var i = 0; i < activeTypes.length; i++)
          Positioned(
            left: 12,
            top:
                this.context.layout.mainChartHeight +
                this.context.layout.secondaryPaneHeight * i +
                5,
            child: _label(activeTypes[i]),
          ),
      ],
    );
  }

  /// 构建指定副图类型的标签。
  Widget _label(KLineDefaultIndicatorType type) {
    return _row(type.label, adapter.secondaryIndicatorEntries(selected, type));
  }

  /// 构建一行副图指标标签。
  Widget _row(String title, List<KLineIndicatorEntry> values) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 8, color: Colors.blue)),
        for (final value in values)
          if (value.value != null)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                '${value.label}:${value.value!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 8,
                  color: context.theme.indicatorColorAt(value.colorIndex),
                ),
              ),
            ),
      ],
    );
  }
}
