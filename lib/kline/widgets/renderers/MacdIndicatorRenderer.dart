import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/renderers/IndicatorRenderer.dart';

/// MACD指标绘制器
class MACDIndicatorRenderer extends BaseIndicatorRenderer {
  @override
  void paint(
    Canvas canvas,
    Size size,
    List<KLineModel> klineModels,
    List<KLinePositionModel> positionModels,
  ) {
    final macdValues =
        klineModels
            .map((e) => e.kLineTechnicalIndicatorsModel?.macd)
            .whereType<double>()
            .toList();
    final difValues =
        klineModels
            .map((e) => e.kLineTechnicalIndicatorsModel?.dif)
            .whereType<double>()
            .toList();
    final deaValues =
        klineModels
            .map((e) => e.kLineTechnicalIndicatorsModel?.dea)
            .whereType<double>()
            .toList();

    if (macdValues.isEmpty) return;

    final allValues = [...macdValues, ...difValues, ...deaValues];
    final maxValue = allValues.reduce(math.max);
    final minValue = allValues.reduce(math.min);

    if (maxValue == minValue) return;

    // 绘制MACD柱状图
    _drawMACDBarChart(
      canvas,
      size,
      (minValue, maxValue),
      klineModels,
      positionModels,
    );

    // 绘制MACD线
    _drawMACDLines(
      canvas,
      size,
      (minValue, maxValue),
      klineModels,
      positionModels,
    );
  }

  void _drawMACDBarChart(
    Canvas canvas,
    Size size,
    (double, double) valueRange,
    List<KLineModel> klineModels,
    List<KLinePositionModel> positionModels,
  ) {
    final config = KLineConfig.shared;
    final positiveBarPath = Path();
    final negativeBarPath = Path();
    final centerY = size.height / 2;
    final range = valueRange.$2 - valueRange.$1;

    for (int i = 0; i < positionModels.length && i < klineModels.length; i++) {
      final indicators = klineModels[i].kLineTechnicalIndicatorsModel;
      if (indicators == null) continue;

      final macd = indicators.macd;
      if (macd == null) continue;

      final normalizedValue = (macd - valueRange.$1) / range;
      final yPosition = size.height - (normalizedValue * size.height);
      final barHeight = (yPosition - centerY).abs();
      final isPositive = macd >= 0;

      final barWidth = config.candleWidth * config.macdBarWidthRatio;
      final barRect = Rect.fromLTWH(
        positionModels[i].candleCenterX - barWidth / 2,
        centerY - (isPositive ? barHeight : 0),
        barWidth,
        barHeight,
      );

      if (isPositive) {
        positiveBarPath.addRect(barRect);
      } else {
        negativeBarPath.addRect(barRect);
      }
    }

    // 绘制正值柱状图
    final positiveBarPaint =
        Paint()
          ..color = config.candleUpColor
          ..style = PaintingStyle.fill;
    canvas.drawPath(positiveBarPath, positiveBarPaint);

    // 绘制负值柱状图
    final negativeBarPaint =
        Paint()
          ..color = config.candleDownColor
          ..style = PaintingStyle.fill;
    canvas.drawPath(negativeBarPath, negativeBarPaint);
  }

  void _drawMACDLines(
    Canvas canvas,
    Size size,
    (double, double) valueRange,
    List<KLineModel> klineModels,
    List<KLinePositionModel> positionModels,
  ) {
    final config = KLineConfig.shared;

    // 计算DIF线位置
    final difPoints = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.dif,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算DEA线位置
    final deaPoints = calculateLinePoints(
      layerSize: size,
      valueRange: valueRange,
      valueExtractor: (indicators) => indicators.dea,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    drawLineChart(canvas, size, [
      (difPoints, config.macdDifColor, 'DIF'),
      (deaPoints, config.macdDeaColor, 'DEA'),
    ]);
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
      title: 'MACD:',
      titleColor: config.macdDifColor,
      values: [
        ('DIF', indicators.dif, config.macdDifColor),
        ('DEA', indicators.dea, config.macdDeaColor),
        ('MACD', indicators.macd, config.indicatorTextColor),
      ],
    );
  }
}
