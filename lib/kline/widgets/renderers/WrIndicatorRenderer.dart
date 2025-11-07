import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/renderers/IndicatorRenderer.dart';

/// WR指标绘制器
class WRIndicatorRenderer extends BaseIndicatorRenderer {
  @override
  void paint(Canvas canvas, Size size, List<KLineModel> klineModels, List<KLinePositionModel> positionModels) {
    final config = KLineConfig.shared;

    // 计算数据范围
    final valueRange = _calculateValueRange(klineModels);
    if (valueRange.$1 >= valueRange.$2) return;

    // 计算WR6线位置
    final wr6Points = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.wr6,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算WR10线位置
    final wr10Points = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.wr10,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算WR14线位置
    final wr14Points = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.wr14,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    drawLineChart(canvas, size, [
      (wr6Points, config.wr6Color, 'WR6'),
      (wr10Points, config.wr10Color, 'WR10'),
      (wr14Points, config.wr14Color, 'WR14'),
    ]);
  }

  (double, double) _calculateValueRange(List<KLineModel> klineModels) {
    final allValues = <double>[];

    for (final model in klineModels) {
      final indicators = model.kLineTechnicalIndicatorsModel;
      if (indicators != null) {
        if (indicators.wr6 != null) allValues.add(indicators.wr6!);
        if (indicators.wr10 != null) allValues.add(indicators.wr10!);
        if (indicators.wr14 != null) allValues.add(indicators.wr14!);
      }
    }

    if (allValues.isEmpty) return (-100.0, 0.0);

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
      title: 'WR:',
      titleColor: config.wr6Color,
      values: [
        ('WR6', indicators.wr6, config.wr6Color),
        ('WR10', indicators.wr10, config.wr10Color),
        ('WR14', indicators.wr14, config.wr14Color),
      ],
    );
  }
}
