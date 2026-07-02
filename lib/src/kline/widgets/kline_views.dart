import 'package:flutter/material.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';
import 'package:kline_flutter/src/kline/widgets/delegate_impl/kline_data_adapter.dart';

/// 默认底部指标选择器。
class KLineDefaultIndicatorSelector<T> extends StatelessWidget {
  const KLineDefaultIndicatorSelector({
    super.key,
    required this.context,
    required this.mainIndicators,
    required this.secondaryIndicators,
  });

  /// 当前图表上下文。
  final KLineChartContext<T> context;

  /// 可选择的主图指标。
  final List<KLineIndicatorSpec<T>> mainIndicators;

  /// 可选择的副图指标。
  final List<KLineIndicatorSpec<T>> secondaryIndicators;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: this.context.controller,
      builder: (context, _) {
        return SizedBox(
          height: this.context.layout.indicatorSelectorHeight,
          child: ColoredBox(
            color: Colors.white,
            child: Row(
              children: [
                for (final indicator in mainIndicators)
                  Expanded(child: _button(indicator)),
                Container(width: 1, height: 10, color: Colors.grey[400]),
                for (final indicator in secondaryIndicators)
                  Expanded(child: _button(indicator)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _button(KLineIndicatorSpec<T> indicator) {
    final selected = context.controller.activeIndicatorIds.contains(
      indicator.id,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.controller.toggleIndicator(indicator.id),
      child: Center(
        child: Text(
          indicator.label,
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
class MainIndicatorLabels<T> extends StatelessWidget {
  const MainIndicatorLabels({
    super.key,
    required this.context,
    required this.selected,
    required this.adapter,
    required this.indicators,
  });

  final KLineChartContext<T> context;
  final T selected;
  final KLineDataAdapter<T> adapter;
  final List<KLineIndicatorSpec<T>> indicators;

  @override
  Widget build(BuildContext context) {
    final active = this.context.controller.activeIndicatorIds;
    return Positioned(
      left: 12,
      top: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final indicator in indicators)
            if (active.contains(indicator.id))
              _row(
                adapter.mainIndicatorEntries(selected, indicator),
                title:
                    indicator.id == KLineDefaultIndicators.bollId
                        ? indicator.label
                        : null,
              ),
        ],
      ),
    );
  }

  Widget _row(List<KLineIndicatorEntry> values, {String? title}) {
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
    return Row(
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 2),
            child: Text(
              '$title:',
              style: const TextStyle(color: Colors.blue, fontSize: 9),
            ),
          ),
        ...children,
      ],
    );
  }
}

/// 默认副图指标标签。
class SecondaryIndicatorLabels<T> extends StatelessWidget {
  const SecondaryIndicatorLabels({
    super.key,
    required this.context,
    required this.selected,
    required this.adapter,
    required this.indicators,
    required this.indicatorHeight,
  });

  final KLineChartContext<T> context;
  final T selected;
  final KLineDataAdapter<T> adapter;
  final List<KLineIndicatorSpec<T>> indicators;
  final KLineIndicatorHeightGetter<T> indicatorHeight;

  @override
  Widget build(BuildContext context) {
    final active = this.context.controller.activeIndicatorIds;
    final children = <Widget>[];
    var top = this.context.layout.mainChartHeight;
    for (final indicator in indicators) {
      if (!active.contains(indicator.id)) continue;
      children.add(
        Positioned(left: 12, top: top + 5, child: _label(indicator)),
      );
      top += indicatorHeight(this.context, indicator);
    }
    return Stack(children: children);
  }

  Widget _label(KLineIndicatorSpec<T> indicator) {
    return _row(
      indicator.label,
      adapter.secondaryIndicatorEntries(selected, indicator),
    );
  }

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

class KLineSelectionDetailPanel extends StatelessWidget {
  const KLineSelectionDetailPanel({super.key, required this.entries});

  final List<KLineDetailEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6D9D9D9),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 90),
          child: Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
              2: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children:
                entries
                    .map(
                      (entry) => TableRow(
                        children: [
                          _KLineSelectionDetailText(entry.label),
                          const SizedBox(width: 24),
                          _KLineSelectionDetailText(
                            entry.value,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }
}

class _KLineSelectionDetailText extends StatelessWidget {
  const _KLineSelectionDetailText(this.text, {this.textAlign = TextAlign.left});

  final String text;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        textAlign: textAlign,
        style: const TextStyle(fontSize: 10, color: Colors.black87),
      ),
    );
  }
}
