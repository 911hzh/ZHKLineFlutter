import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/renderers/IndicatorRenderer.dart';

/// KDJ指标绘制器
class KDJIndicatorRenderer extends BaseIndicatorRenderer {
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

    // 计算K线位置
    final kPoints = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.k,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算D线位置
    final dPoints = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.d,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算J线位置
    final jPoints = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.j,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    drawLineChart(canvas, size, [
      (kPoints, config.kdjKColor, 'K'),
      (dPoints, config.kdjDColor, 'D'),
      (jPoints, config.kdjJColor, 'J'),
    ]);
  }

  (double, double) _calculateValueRange(List<KLineModel> klineModels) {
    final allValues = <double>[];

    for (final model in klineModels) {
      final indicators = model.kLineTechnicalIndicatorsModel;
      if (indicators != null) {
        if (indicators.k != null) allValues.add(indicators.k!);
        if (indicators.d != null) allValues.add(indicators.d!);
        if (indicators.j != null) allValues.add(indicators.j!);
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
      title: 'KDJ:',
      titleColor: config.kdjKColor,
      values: [
        ('K', indicators.k, config.kdjKColor),
        ('D', indicators.d, config.kdjDColor),
        ('J', indicators.j, config.kdjJColor),
      ],
    );
  }
}
