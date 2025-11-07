import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';

/// 技术指标选择控制视图委托
typedef KTechnicalIndicatorControlViewDelegate = void Function(List<KLineTechnicalIndicatorType> types);

/// 技术指标选择控制视图
/// 对应 Swift 版本的 KTechnicalIndicatorControlView
class KTechnicalIndicatorControlView extends StatefulWidget {
  final KTechnicalIndicatorControlViewDelegate? onIndicatorSelectionChanged;
  final List<KLineTechnicalIndicatorType> initialSelection;

  const KTechnicalIndicatorControlView({super.key, this.onIndicatorSelectionChanged, this.initialSelection = const []});

  @override
  State<KTechnicalIndicatorControlView> createState() => _KTechnicalIndicatorControlViewState();
}

class _KTechnicalIndicatorControlViewState extends State<KTechnicalIndicatorControlView> {
  /// 当前选中的指标类型集合（支持多选）
  late List<KLineTechnicalIndicatorType> _selectedIndicatorTypes;

  /// 主图指标类型和标题映射
  final List<(KLineTechnicalIndicatorType, String)> _mainIndicatorTitles = [
    (KLineTechnicalIndicatorType.ma, 'MA'),
    (KLineTechnicalIndicatorType.ema, 'EMA'),
    (KLineTechnicalIndicatorType.boll, 'BOLL'),
  ];

  /// 副图指标类型和标题映射
  final List<(KLineTechnicalIndicatorType, String)> _secondIndicatorTitles = [
    (KLineTechnicalIndicatorType.volume, 'VOL'),
    (KLineTechnicalIndicatorType.macd, 'MACD'),
    (KLineTechnicalIndicatorType.kdj, 'KDJ'),
    (KLineTechnicalIndicatorType.rsi, 'RSI'),
    (KLineTechnicalIndicatorType.wr, 'WR'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndicatorTypes = List.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _mainIndicatorTitles.length + _secondIndicatorTitles.length;
    final separatorWidth = 1.0;

    return Container(
      height: 30,
      color: Colors.white,
      child: Row(
        children: [
          // 主图指标按钮
          ..._mainIndicatorTitles.map((item) {
            return Expanded(child: _buildIndicatorButton(item.$2, item.$1));
          }),

          // 分割线
          Container(width: separatorWidth, margin: const EdgeInsets.symmetric(vertical: 10), color: Colors.grey[400]),

          // 副图指标按钮
          ..._secondIndicatorTitles.map((item) {
            return Expanded(child: _buildIndicatorButton(item.$2, item.$1));
          }),
        ],
      ),
    );
  }

  /// 创建指标按钮
  Widget _buildIndicatorButton(String title, KLineTechnicalIndicatorType type) {
    final isSelected = _selectedIndicatorTypes.contains(type);

    return GestureDetector(
      onTap: () => _onIndicatorButtonTapped(type),
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? Colors.black : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  /// 指标按钮点击事件
  void _onIndicatorButtonTapped(KLineTechnicalIndicatorType type) {
    setState(() {
      // 切换选择状态（支持多选）
      if (_selectedIndicatorTypes.contains(type)) {
        _selectedIndicatorTypes.remove(type);
      } else {
        _selectedIndicatorTypes.add(type);
      }
    });

    // 通知委托
    widget.onIndicatorSelectionChanged?.call(_selectedIndicatorTypes);
  }
}
