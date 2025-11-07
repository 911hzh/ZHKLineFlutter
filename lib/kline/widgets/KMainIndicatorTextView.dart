import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';

/// 主图技术指标文本显示视图
class KMainIndicatorTextView extends StatelessWidget {
  final KLineModel? selectedKLineModel;
  final List<KLineTechnicalIndicatorType> indicatorSelection;

  const KMainIndicatorTextView({Key? key, this.selectedKLineModel, required this.indicatorSelection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedKLineModel == null) {
      return const SizedBox.shrink();
    }

    final indicators = selectedKLineModel!.kLineTechnicalIndicatorsModel;
    if (indicators == null) {
      return const SizedBox.shrink();
    }

    final config = KLineConfig.shared;

    return Positioned(
      top: 5,
      left: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MA 指标
          if (indicatorSelection.contains(KLineTechnicalIndicatorType.ma))
            _buildIndicatorRow(
              values: [
                if (indicators.ma5 != null)
                  _IndicatorValue(name: 'MA5', value: indicators.ma5!, color: config.ma5Color),
                if (indicators.ma10 != null)
                  _IndicatorValue(name: 'MA10', value: indicators.ma10!, color: config.ma10Color),
                if (indicators.ma30 != null)
                  _IndicatorValue(name: 'MA30', value: indicators.ma30!, color: config.ma30Color),
              ],
            ),

          // EMA 指标
          if (indicatorSelection.contains(KLineTechnicalIndicatorType.ema))
            _buildIndicatorRow(
              values: [
                if (indicators.ema5 != null)
                  _IndicatorValue(name: 'EMA5', value: indicators.ema5!, color: config.ema5Color),
                if (indicators.ema10 != null)
                  _IndicatorValue(name: 'EMA10', value: indicators.ema10!, color: config.ema10Color),
                if (indicators.ema30 != null)
                  _IndicatorValue(name: 'EMA30', value: indicators.ema30!, color: config.ema30Color),
              ],
            ),

          // BOLL 指标
          if (indicatorSelection.contains(KLineTechnicalIndicatorType.boll))
            _buildIndicatorRow(
              values: [
                if (indicators.bollUpper != null)
                  _IndicatorValue(name: 'UPPER', value: indicators.bollUpper!, color: config.bollUpperColor),
                if (indicators.bollMiddle != null)
                  _IndicatorValue(name: 'MB', value: indicators.bollMiddle!, color: config.bollMiddleColor),
                if (indicators.bollLower != null)
                  _IndicatorValue(name: 'LOWER', value: indicators.bollLower!, color: config.bollLowerColor),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildIndicatorRow({required List<_IndicatorValue> values}) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children:
            values
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${value.name}:${value.value.toStringAsFixed(2)}',
                      style: TextStyle(color: value.color, fontSize: 9, backgroundColor: Colors.transparent),
                    ),
                  ),
                )
                .toList(),
      ),
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
