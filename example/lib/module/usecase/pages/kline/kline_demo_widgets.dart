// ignore_for_file: file_names

// K 线 Demo 页面组件：顶部栏、周期选择器和指标选择器。
part of 'KLineDemoPage.dart';

/// 顶部标题栏，保留旧 Demo 的标题和关闭按钮样式。
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'K线图表',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '关闭',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 周期选择栏，负责展示 15分/1时/4时/1日/1周 与右侧操作按钮。
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onSelected,
    required this.onZoom,
  });

  final KLinePeriod selectedPeriod;
  final ValueChanged<KLinePeriod> onSelected;
  final VoidCallback onZoom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: KLinePeriod.values.map((period) {
                final selected = period == selectedPeriod;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelected(period),
                    child: Center(
                      child: Text(
                        _periodText(period),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _controlButton(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '更多',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  () {},
                ),
                _controlButton(
                  Icon(Icons.settings, size: 20, color: Colors.grey[600]),
                  () {},
                ),
                _controlButton(
                  Icon(Icons.search, size: 20, color: Colors.grey[600]),
                  onZoom,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(Widget child, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    );
  }

  String _periodText(KLinePeriod period) {
    switch (period) {
      case KLinePeriod.min15:
        return '15分';
      case KLinePeriod.min60:
        return '1时';
      case KLinePeriod.hour4:
        return '4时';
      case KLinePeriod.day1:
        return '1日';
      case KLinePeriod.mon1:
        return '1周';
    }
  }
}
