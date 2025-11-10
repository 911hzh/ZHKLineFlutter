import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';

/// 指标绘制器接口
abstract class IndicatorRenderer {
  /// 绘制指标内容
  void paint(
    Canvas canvas,
    Size size,
    List<KLineModel> klineModels,
    List<KLinePositionModel> positionModels,
  );

  /// 绘制坐标轴标签
  void paintCoordinateLabels(
    Canvas canvas,
    Size size,
    KLineTechnicalIndicatorType indicatorType,
    List<KLineModel> klineModels,
  );

  /// 绘制指标数值标签
  void paintIndicatorValueLabels(
    Canvas canvas,
    Size size,
    KLineTechnicalIndicatorType indicatorType,
    List<KLineModel> klineModels,
    KLineModel? selectedKLineModel,
  );
}

/// 基础指标绘制器，提供通用方法
abstract class BaseIndicatorRenderer implements IndicatorRenderer {
  /// 计算线条位置点
  List<Offset> calculateLinePoints({
    required Size layerSize,
    required (double min, double max) valueRange,
    required double? Function(dynamic) valueExtractor,
    required List<KLineModel> klineModels,
    required List<KLinePositionModel> positionModels,
  }) {
    List<Offset> points = [];
    final range = valueRange.$2 - valueRange.$1;

    for (int i = 0; i < positionModels.length && i < klineModels.length; i++) {
      final indicators = klineModels[i].kLineTechnicalIndicatorsModel;
      if (indicators != null) {
        final value = valueExtractor(indicators);
        if (value != null) {
          final normalizedValue = (value - valueRange.$1) / range;
          final yPosition =
              layerSize.height - (normalizedValue * layerSize.height);
          points.add(Offset(positionModels[i].candleCenterX, yPosition));
        }
      }
    }

    return points;
  }

  /// 绘制通用折线图
  void drawLineChart(
    Canvas canvas,
    Size layerSize,
    List<(List<Offset> points, Color color, String name)> lines,
  ) {
    for (final lineData in lines) {
      if (lineData.$1.length < 2) continue;

      final paint =
          Paint()
            ..color = lineData.$2
            ..style = PaintingStyle.stroke
            ..strokeWidth = KLineConfig.shared.indicatorLineWidth;

      final path = Path();
      path.moveTo(lineData.$1[0].dx, lineData.$1[0].dy);

      for (int i = 1; i < lineData.$1.length; i++) {
        path.lineTo(lineData.$1[i].dx, lineData.$1[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  void paintCoordinateLabels(
    Canvas canvas,
    Size size,
    KLineTechnicalIndicatorType indicatorType,
    List<KLineModel> klineModels,
  ) {
    // 绘制指标名称
    _paintIndicatorName(canvas, size, indicatorType);

    // 绘制Y轴数值标签
    _paintYAxisValueLabels(canvas, size, indicatorType, klineModels);
  }

  @override
  void paintIndicatorValueLabels(
    Canvas canvas,
    Size size,
    KLineTechnicalIndicatorType indicatorType,
    List<KLineModel> klineModels,
    KLineModel? selectedKLineModel,
  ) {
    // 子类可以重写此方法提供特定的数值标签绘制逻辑
  }

  /// 绘制指标名称标签
  void _paintIndicatorName(
    Canvas canvas,
    Size size,
    KLineTechnicalIndicatorType indicatorType,
  ) {
    String name = '';
    switch (indicatorType) {
      case KLineTechnicalIndicatorType.volume:
        name = 'VOL';
        break;
      case KLineTechnicalIndicatorType.macd:
        name = 'MACD';
        break;
      case KLineTechnicalIndicatorType.kdj:
        name = 'KDJ';
        break;
      case KLineTechnicalIndicatorType.rsi:
        name = 'RSI';
        break;
      case KLineTechnicalIndicatorType.wr:
        name = 'WR';
        break;
      default:
        break;
    }

    if (name.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 60, 5));
    }
  }

  /// 绘制Y轴数值标签
  void _paintYAxisValueLabels(
    Canvas canvas,
    Size size,
    KLineTechnicalIndicatorType indicatorType,
    List<KLineModel> klineModels,
  ) {
    const labelCount = 3;
    const labelHeight = 12.0;
    const labelWidth = 50.0;

    final valueRange = _calculateValueRange(indicatorType, klineModels);

    for (int i = 0; i < labelCount; i++) {
      final yPosition = (size.height - labelHeight) * i / (labelCount - 1);
      final labelValue = _calculateLabelValue(
        indicatorType,
        i,
        labelCount,
        valueRange,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labelValue,
          style: TextStyle(color: Colors.grey[400], fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout(maxWidth: labelWidth);
      textPainter.paint(canvas, Offset(size.width - labelWidth - 5, yPosition));
    }
  }

  /// 计算标签数值
  String _calculateLabelValue(
    KLineTechnicalIndicatorType indicatorType,
    int position,
    int totalPositions,
    (double min, double max) valueRange,
  ) {
    final ratio = (totalPositions - 1 - position) / (totalPositions - 1);
    final value = valueRange.$1 + ratio * (valueRange.$2 - valueRange.$1);

    switch (indicatorType) {
      case KLineTechnicalIndicatorType.kdj:
      case KLineTechnicalIndicatorType.rsi:
      case KLineTechnicalIndicatorType.wr:
        return value.toStringAsFixed(1);
      case KLineTechnicalIndicatorType.volume:
        return _formatVolumeValue(value);
      case KLineTechnicalIndicatorType.macd:
        return value.toStringAsFixed(4);
      default:
        return value.toStringAsFixed(2);
    }
  }

  /// 格式化成交量数值
  String _formatVolumeValue(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// 计算指标的数据范围
  (double min, double max) _calculateValueRange(
    KLineTechnicalIndicatorType indicatorType,
    List<KLineModel> klineModels,
  ) {
    List<double> allValues = [];

    for (final klineModel in klineModels) {
      final indicators = klineModel.kLineTechnicalIndicatorsModel;
      if (indicators == null) continue;

      switch (indicatorType) {
        case KLineTechnicalIndicatorType.kdj:
          if (indicators.k != null) allValues.add(indicators.k!);
          if (indicators.d != null) allValues.add(indicators.d!);
          if (indicators.j != null) allValues.add(indicators.j!);
          break;
        case KLineTechnicalIndicatorType.rsi:
          if (indicators.rsi6 != null) allValues.add(indicators.rsi6!);
          if (indicators.rsi12 != null) allValues.add(indicators.rsi12!);
          if (indicators.rsi24 != null) allValues.add(indicators.rsi24!);
          break;
        case KLineTechnicalIndicatorType.wr:
          if (indicators.wr6 != null) allValues.add(indicators.wr6!);
          if (indicators.wr10 != null) allValues.add(indicators.wr10!);
          if (indicators.wr14 != null) allValues.add(indicators.wr14!);
          break;
        case KLineTechnicalIndicatorType.volume:
          if (indicators.volumeMA5 != null)
            allValues.add(indicators.volumeMA5!);
          if (indicators.volumeMA10 != null)
            allValues.add(indicators.volumeMA10!);
          break;
        case KLineTechnicalIndicatorType.macd:
          if (indicators.dif != null) allValues.add(indicators.dif!);
          if (indicators.dea != null) allValues.add(indicators.dea!);
          if (indicators.macd != null) allValues.add(indicators.macd!);
          break;
        default:
          break;
      }
    }

    if (allValues.isEmpty) {
      return (0.0, 100.0);
    }

    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);

    final range = maxValue - minValue;
    final adjustedMin = range > 0 ? minValue : minValue - 5;
    final adjustedMax = range > 0 ? maxValue : maxValue + 5;

    return (adjustedMin, adjustedMax);
  }

  /// 创建副图指标标签
  void paintSecondaryIndicatorLabels(
    Canvas canvas, {
    required double xOffset,
    required double yPosition,
    required double labelHeight,
    required double spacing,
    required String title,
    required Color titleColor,
    required List<(String name, double? value, Color color)> values,
  }) {
    double currentX = xOffset;

    // 绘制标题
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(color: titleColor, fontSize: 8),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, Offset(currentX, yPosition));
    currentX += titlePainter.width + spacing;

    // 绘制各个数值
    for (final (name, value, color) in values) {
      if (value != null) {
        final valueText = '$name:${value.toStringAsFixed(2)}';
        final valuePainter = TextPainter(
          text: TextSpan(
            text: valueText,
            style: TextStyle(color: color, fontSize: 8),
          ),
          textDirection: TextDirection.ltr,
        );
        valuePainter.layout();
        valuePainter.paint(canvas, Offset(currentX, yPosition));
        currentX += valuePainter.width + spacing;
      }
    }
  }
}
