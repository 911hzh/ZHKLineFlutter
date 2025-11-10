import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/renderers/IndicatorRenderer.dart';

/// RSI指标绘制器
class RSIIndicatorRenderer extends BaseIndicatorRenderer {
  @override
  void paint(
    Canvas canvas,
    Size size,
    List<KLineModel> klineModels,
    List<KLinePositionModel> positionModels,
  ) {
    final config = KLineConfig.shared;

    // 计算数据范围
    final valueRange = _calculateValueRange(klineModels);
    if (valueRange.$1 >= valueRange.$2) return;

    // 计算RSI6线位置
    final rsi6Points = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.rsi6,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算RSI12线位置
    final rsi12Points = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.rsi12,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算RSI24线位置
    final rsi24Points = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.rsi24,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    drawLineChart(canvas, size, [
      (rsi6Points, config.rsi6Color, 'RSI6'),
      (rsi12Points, config.rsi12Color, 'RSI12'),
      (rsi24Points, config.rsi24Color, 'RSI24'),
    ]);
  }

  (double, double) _calculateValueRange(List<KLineModel> klineModels) {
    final allValues = <double>[];

    for (final model in klineModels) {
      final indicators = model.kLineTechnicalIndicatorsModel;
      if (indicators != null) {
        if (indicators.rsi6 != null) allValues.add(indicators.rsi6!);
        if (indicators.rsi12 != null) allValues.add(indicators.rsi12!);
        if (indicators.rsi24 != null) allValues.add(indicators.rsi24!);
      }
    }

    if (allValues.isEmpty) return (0.0, 100.0);

    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);

    return (minValue, maxValue);
  }

  @override
  void paintIndicatorValueLabels(
    Canvas canvas,
    Size size,
    KLineTechnicalIndicatorType indicatorType,
    List<KLineModel> klineModels,
    KLineModel? selectedKLineModel,
  ) {
    if (selectedKLineModel == null) return;

    final indicators = selectedKLineModel.kLineTechnicalIndicatorsModel;
    if (indicators == null) return;

    final config = KLineConfig.shared;
    paintSecondaryIndicatorLabels(
      canvas,
      xOffset: 10,
      yPosition: 5,
      labelHeight: 13,
      spacing: 3,
      title: 'RSI:',
      titleColor: config.rsi6Color,
      values: [
        ('RSI6', indicators.rsi6, config.rsi6Color),
        ('RSI12', indicators.rsi12, config.rsi12Color),
        ('RSI24', indicators.rsi24, config.rsi24Color),
      ],
    );
  }
}
