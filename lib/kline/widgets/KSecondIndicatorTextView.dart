import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';

/// 副图技术指标文本显示视图
/// 参考 Swift 版本：每个副图指标的数值标签显示在各自的区域顶部
class KSecondIndicatorTextView extends StatelessWidget {
  final KLineModel? selectedKLineModel;
  final List<KLineTechnicalIndicatorType> indicatorSelection;
  final double baseTopOffset; // 副图区域相对于 KLineView 的顶部偏移

  const KSecondIndicatorTextView({
    Key? key,
    this.selectedKLineModel,
    required this.indicatorSelection,
    required this.baseTopOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedKLineModel == null || indicatorSelection.isEmpty) {
      return const SizedBox.shrink();
    }

    final indicators = selectedKLineModel!.kLineTechnicalIndicatorsModel;
    if (indicators == null) {
      return const SizedBox.shrink();
    }

    final config = KLineConfig.shared;
    final itemHeight = config.crossItemHeight;

    // 为每个副图指标创建独立的标签，显示在各自的区域
    return Stack(
      children:
          indicatorSelection.asMap().entries.map((entry) {
            final index = entry.key;
            final indicatorType = entry.value;
            final yOffset = baseTopOffset + (itemHeight * index);

            return Positioned(
              left: config.chartViewPadding.left + 10,
              top: yOffset + 5,
              child: _buildIndicatorLabel(indicatorType, indicators, config),
            );
          }).toList(),
    );
  }

  /// 为单个指标类型构建标签
  /// 参考 Swift 版本：每个指标都有标题（如 "MACD:", "VOL:" 等）
  Widget _buildIndicatorLabel(KLineTechnicalIndicatorType type, dynamic indicators, KLineConfig config) {
    String title = '';
    Color titleColor = Colors.grey;
    List<_IndicatorValue> values = [];

    switch (type) {
      case KLineTechnicalIndicatorType.macd:
        title = 'MACD:';
        titleColor = config.macdDifColor;
        if (indicators.dif != null)
          values.add(_IndicatorValue(name: 'DIF', value: indicators.dif!, color: config.macdDifColor));
        if (indicators.dea != null)
          values.add(_IndicatorValue(name: 'DEA', value: indicators.dea!, color: config.macdDeaColor));
        if (indicators.macd != null)
          values.add(_IndicatorValue(name: 'MACD', value: indicators.macd!, color: config.indicatorTextColor));
        break;

      case KLineTechnicalIndicatorType.volume:
        title = 'VOL:';
        titleColor = config.volumeMA5Color;
        if (indicators.volumeMA5 != null)
          values.add(_IndicatorValue(name: 'MA5', value: indicators.volumeMA5!, color: config.volumeMA5Color));
        if (indicators.volumeMA10 != null)
          values.add(_IndicatorValue(name: 'MA10', value: indicators.volumeMA10!, color: config.volumeMA10Color));
        break;

      case KLineTechnicalIndicatorType.kdj:
        title = 'KDJ:';
        titleColor = config.kdjKColor;
        if (indicators.k != null) values.add(_IndicatorValue(name: 'K', value: indicators.k!, color: config.kdjKColor));
        if (indicators.d != null) values.add(_IndicatorValue(name: 'D', value: indicators.d!, color: config.kdjDColor));
        if (indicators.j != null) values.add(_IndicatorValue(name: 'J', value: indicators.j!, color: config.kdjJColor));
        break;

      case KLineTechnicalIndicatorType.rsi:
        title = 'RSI:';
        titleColor = config.rsi6Color;
        if (indicators.rsi6 != null)
          values.add(_IndicatorValue(name: 'RSI6', value: indicators.rsi6!, color: config.rsi6Color));
        if (indicators.rsi12 != null)
          values.add(_IndicatorValue(name: 'RSI12', value: indicators.rsi12!, color: config.rsi12Color));
        if (indicators.rsi24 != null)
          values.add(_IndicatorValue(name: 'RSI24', value: indicators.rsi24!, color: config.rsi24Color));
        break;

      case KLineTechnicalIndicatorType.wr:
        title = 'WR:';
        titleColor = config.wr6Color;
        if (indicators.wr6 != null)
          values.add(_IndicatorValue(name: 'WR6', value: indicators.wr6!, color: config.wr6Color));
        if (indicators.wr10 != null)
          values.add(_IndicatorValue(name: 'WR10', value: indicators.wr10!, color: config.wr10Color));
        if (indicators.wr14 != null)
          values.add(_IndicatorValue(name: 'WR14', value: indicators.wr14!, color: config.wr14Color));
        break;

      default:
        break;
    }

    return _buildIndicatorRowWithTitle(title, titleColor, values);
  }

  /// 构建带标题的指标行
  /// 参考 Swift 版本的 createSecondaryIndicatorLabels 方法
  Widget _buildIndicatorRowWithTitle(String title, Color titleColor, List<_IndicatorValue> values) {
    if (values.isEmpty && title.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        // 标题
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(title, style: TextStyle(color: titleColor, fontSize: 8, backgroundColor: Colors.transparent)),
          ),
        // 数值列表
        ...values.map(
          (value) => Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Text(
              '${value.name}:${value.value.toStringAsFixed(2)}',
              style: TextStyle(color: value.color, fontSize: 8, backgroundColor: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}

/// 指标数值数据类
class _IndicatorValue {
  final String name;
  final double value;
  final Color color;

  _IndicatorValue({required this.name, required this.value, required this.color});
}
