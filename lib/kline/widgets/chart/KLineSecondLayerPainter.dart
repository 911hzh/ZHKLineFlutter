import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/renderers/IndicatorRendererFactory.dart';

/// 副图层绘制器
class KLineSecondLayerPainter extends CustomPainter {
  final List<KLineModel> klineModels;
  final List<KLinePositionModel> positionModels;
  final List<KLineTechnicalIndicatorType> needDrawTypes;
  final double itemHeight;
  final KLineModel? selectedKLineModel;

  KLineSecondLayerPainter({
    required this.klineModels,
    required this.positionModels,
    required this.needDrawTypes,
    required this.itemHeight,
    this.selectedKLineModel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (klineModels.isEmpty || needDrawTypes.isEmpty) return;

    // 绘制背景网格
    _drawBackgroundGrid(canvas, size);

    // 为每个副图指标动态计算位置并绘制
    for (int i = 0; i < needDrawTypes.length; i++) {
      final yOffset = itemHeight * i;

      // 使用策略模式处理不同的指标绘制
      final renderer = IndicatorRendererFactory.createRenderer(needDrawTypes[i]);
      if (renderer != null) {
        // 保存画布状态
        canvas.save();
        canvas.translate(0, yOffset);

        // 创建指标内容的子区域大小
        final indicatorSize = Size(size.width, itemHeight);

        // 绘制指标内容
        renderer.paint(canvas, indicatorSize, klineModels, positionModels);

        // 绘制坐标轴标签
        renderer.paintCoordinateLabels(canvas, indicatorSize, needDrawTypes[i], klineModels);

        // 注意：指标数值标签不在这里绘制，而是在固定层绘制
        // renderer.paintIndicatorValueLabels(canvas, indicatorSize, needDrawTypes[i], klineModels, selectedKLineModel);

        // 恢复画布状态
        canvas.restore();
      }
    }
  }

  /// 绘制背景网格
  void _drawBackgroundGrid(Canvas canvas, Size size) {
    final config = KLineConfig.shared;
    final paint =
        Paint()
          ..color = config.crossLineColor
          ..strokeWidth = config.crossLineWidth
          ..style = PaintingStyle.stroke;

    final offset = config.crossLineWidth / 2.0;

    for (int i = 0; i < needDrawTypes.length; i++) {
      final yOffset = itemHeight * i;

      // 绘制顶部分隔线（每个指标区域的顶部）
      canvas.drawLine(Offset(offset, yOffset + offset), Offset(size.width - offset, yOffset + offset), paint);

      // 绘制中间的那条线
      canvas.drawLine(
        Offset(offset, yOffset + itemHeight - 20),
        Offset(size.width - offset, yOffset + itemHeight - 20),
        paint,
      );

      // 绘制底部的那条线
      canvas.drawLine(
        Offset(offset, yOffset + itemHeight - offset),
        Offset(size.width - offset, yOffset + itemHeight - offset),
        paint,
      );

      // 绘制竖线
      final itemWidth = (size.width - offset * 2) / (config.crossVerticalCount - 1);
      double lastX = offset;

      for (int j = 0; j < config.crossVerticalCount; j++) {
        canvas.drawLine(Offset(lastX, yOffset + offset), Offset(lastX, yOffset + itemHeight - offset), paint);
        lastX += itemWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant KLineSecondLayerPainter oldDelegate) {
    return oldDelegate.klineModels != klineModels ||
        oldDelegate.positionModels != positionModels ||
        oldDelegate.needDrawTypes != needDrawTypes ||
        oldDelegate.selectedKLineModel != selectedKLineModel;
  }
}
