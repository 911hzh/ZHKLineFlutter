import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';

/// K线周期选择视图
class KLinePeriodView extends StatefulWidget {
  final KLinePeriod selectedPeriod;
  final ValueChanged<KLinePeriod>? onPeriodSelected;
  final VoidCallback? onMoreButtonTapped;
  final VoidCallback? onSettingsButtonTapped;
  final VoidCallback? onZoomButtonTapped;

  const KLinePeriodView({
    super.key,
    required this.selectedPeriod,
    this.onPeriodSelected,
    this.onMoreButtonTapped,
    this.onSettingsButtonTapped,
    this.onZoomButtonTapped,
  });

  @override
  State<KLinePeriodView> createState() => _KLinePeriodViewState();
}

class _KLinePeriodViewState extends State<KLinePeriodView> {
  late KLinePeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedPeriod;
  }

  @override
  void didUpdateWidget(KLinePeriodView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPeriod != oldWidget.selectedPeriod) {
      setState(() {
        _selectedPeriod = widget.selectedPeriod;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: Colors.transparent,
      child: Row(
        children: [
          // 左侧：周期选择按钮 (60%)
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  KLinePeriod.values.map((period) {
                    final isSelected = period == _selectedPeriod;
                    return Expanded(
                      child: _buildPeriodButton(
                        text: _getPeriodDisplayText(period),
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedPeriod = period;
                          });
                          widget.onPeriodSelected?.call(period);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),

          // 右侧：控制按钮 (40%)
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 更多按钮
                _buildControlButton(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('更多', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.grey[600]),
                    ],
                  ),
                  onTap: widget.onMoreButtonTapped,
                ),

                // 设置按钮
                _buildControlButton(
                  child: Icon(Icons.settings, size: 20, color: Colors.grey[600]),
                  onTap: widget.onSettingsButtonTapped,
                ),

                // 放大按钮
                _buildControlButton(
                  child: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                  onTap: widget.onZoomButtonTapped,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建周期按钮
  Widget _buildPeriodButton({required String text, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: const EdgeInsets.all(8), color: Colors.transparent, child: child),
    );
  }

  /// 获取周期显示文本
  String _getPeriodDisplayText(KLinePeriod period) {
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
