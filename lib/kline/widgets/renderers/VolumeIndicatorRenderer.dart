import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/renderers/IndicatorRenderer.dart';

/// 成交量指标绘制器
class VolumeIndicatorRenderer extends BaseIndicatorRenderer {
  @override
  void paint(Canvas canvas, Size size, List<KLineModel> klineModels, List<KLinePositionModel> positionModels) {
    final volumes = klineModels.map((e) => e.volume).toList();
    final maxVolume = volumes.isEmpty ? 0.0 : volumes.reduce((a, b) => a > b ? a : b);

    if (maxVolume == 0) return;

    // 绘制成交量柱状图
    _drawVolumeBarChart(canvas, size, maxVolume, klineModels, positionModels);

    // 绘制成交量MA线
    _drawVolumeMALines(canvas, size, maxVolume, klineModels, positionModels);
  }

  void _drawVolumeBarChart(
    Canvas canvas,
    Size size,
    double maxVolume,
    List<KLineModel> klineModels,
    List<KLinePositionModel> positionModels,
  ) {
    final config = KLineConfig.shared;
    final upPath = Path();
    final downPath = Path();

    for (int i = 0; i < positionModels.length && i < klineModels.length; i++) {
      final volume = klineModels[i].volume;
      final height = size.height * 0.8 * (volume / maxVolume);
      final yPosition = size.height - height;
      final isRising = klineModels[i].isRising;

      final barWidth = config.candleWidth * config.volumeBarWidthRatio;
      final barRect = Rect.fromLTWH(positionModels[i].candleCenterX - barWidth / 2, yPosition, barWidth, height);

      if (isRising) {
        upPath.addRect(barRect);
      } else {
        downPath.addRect(barRect);
      }
    }

    // 绘制涨势柱状图
    final upPaint =
        Paint()
          ..color = config.candleUpColor
          ..style = PaintingStyle.fill;
    canvas.drawPath(upPath, upPaint);

    // 绘制跌势柱状图
    final downPaint =
        Paint()
          ..color = config.candleDownColor
          ..style = PaintingStyle.fill;
    canvas.drawPath(downPath, downPaint);
  }

  void _drawVolumeMALines(
    Canvas canvas,
    Size size,
    double maxVolume,
    List<KLineModel> klineModels,
    List<KLinePositionModel> positionModels,
  ) {
    final config = KLineConfig.shared;

    // 计算成交量MA5线位置
    final volumeMA5Points = calculateLinePoints(
      layerSize: size,
      valueRange: (0, maxVolume),
      valueExtractor: (indicators) => indicators.volumeMA5,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    // 计算成交量MA10线位置
    final volumeMA10Points = calculateLinePoints(
      layerSize: size,
      valueRange: (0, maxVolume),
      valueExtractor: (indicators) => indicators.volumeMA10,
      klineModels: klineModels,
      positionModels: positionModels,
    );

    drawLineChart(canvas, size, [
      (volumeMA5Points, config.volumeMA5Color, 'MA5'),
      (volumeMA10Points, config.volumeMA10Color, 'MA10'),
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
      title: 'VOL:',
      titleColor: config.volumeMA5Color,
      values: [
        ('MA5', indicators.volumeMA5, config.volumeMA5Color),
        ('MA10', indicators.volumeMA10, config.volumeMA10Color),
      ],
    );
  }
}
