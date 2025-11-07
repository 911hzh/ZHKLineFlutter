import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';

/// K线基础绘制器
class KLineMainPainter extends CustomPainter {
  final List<KLineModel> datas;
  final List<KLinePositionModel> positionDatas;
  final double maxPrice;
  final double minPrice;
  final List<KLineTechnicalIndicatorType> mainChartIndicatorSelection;

  KLineMainPainter({
    required this.datas,
    required this.positionDatas,
    required this.maxPrice,
    required this.minPrice,
    this.mainChartIndicatorSelection = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (datas.isEmpty || positionDatas.isEmpty) return;

    // 绘制蜡烛图
    _drawCandles(canvas, size);

    // 绘制主图技术指标
    _drawMainTechnicalIndicators(canvas, size);
  }

  /// 绘制蜡烛图
  void _drawCandles(Canvas canvas, Size size) {
    final config = KLineConfig.shared;

    // 分别创建涨跌蜡烛的路径
    final upPath = Path();
    final downPath = Path();

    for (int i = 0; i < datas.length && i < positionDatas.length; i++) {
      final klineModel = datas[i];
      final position = positionDatas[i];

      final isRising = klineModel.close >= klineModel.open;

      // 创建完整路径（实体 + 影线）
      final completePath = Path();

      // 添加蜡烛实体
      completePath.addRect(position.candleBodyRect);

      // 添加上影线
      completePath.moveTo(position.candleCenterX, position.candleUpperWickTopY);
      final topY =
          position.candleBodyTopY < position.candleBodyBottomY
              ? position.candleBodyTopY
              : position.candleBodyBottomY;
      completePath.lineTo(position.candleCenterX, topY);

      // 添加下影线
      final bottomY =
          position.candleBodyTopY > position.candleBodyBottomY
              ? position.candleBodyTopY
              : position.candleBodyBottomY;
      completePath.moveTo(position.candleCenterX, bottomY);
      completePath.lineTo(
        position.candleCenterX,
        position.candleLowerWickBottomY,
      );

      // 根据涨跌情况添加到不同的路径
      if (isRising) {
        upPath.addPath(completePath, Offset.zero);
      } else {
        downPath.addPath(completePath, Offset.zero);
      }
    }

    // 绘制涨势蜡烛
    final upPaint =
        Paint()
          ..color = config.candleUpColor
          ..style = PaintingStyle.fill
          ..strokeWidth = config.candleMidleLineWidth;

    canvas.drawPath(upPath, upPaint);

    // 绘制跌势蜡烛
    final downPaint =
        Paint()
          ..color = config.candleDownColor
          ..style = PaintingStyle.fill
          ..strokeWidth = config.candleMidleLineWidth;

    canvas.drawPath(downPath, downPaint);
  }

  /// 绘制主图技术指标
  void _drawMainTechnicalIndicators(Canvas canvas, Size size) {
    final config = KLineConfig.shared;

    // 绘制MA指标
    if (mainChartIndicatorSelection.contains(KLineTechnicalIndicatorType.ma)) {
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.ma5Point).toList(),
        config.ma5Color,
      );
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.ma10Point).toList(),
        config.ma10Color,
      );
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.ma30Point).toList(),
        config.ma30Color,
      );
    }

    // 绘制EMA指标
    if (mainChartIndicatorSelection.contains(KLineTechnicalIndicatorType.ema)) {
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.ema5Point).toList(),
        config.ema5Color,
      );
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.ema10Point).toList(),
        config.ema10Color,
      );
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.ema30Point).toList(),
        config.ema30Color,
      );
    }

    // 绘制BOLL指标
    if (mainChartIndicatorSelection.contains(
      KLineTechnicalIndicatorType.boll,
    )) {
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.bollUpperPoint).toList(),
        config.bollUpperColor,
      );
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.bollMiddlePoint).toList(),
        config.bollMiddleColor,
      );
      _drawIndicatorLine(
        canvas,
        positionDatas.map((p) => p.indicatorPosition?.bollLowerPoint).toList(),
        config.bollLowerColor,
      );
    }
  }

  /// 绘制技术指标线
  void _drawIndicatorLine(Canvas canvas, List<Offset?> points, Color color) {
    final validPoints = points.whereType<Offset>().toList();
    if (validPoints.length < 2) return;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = KLineConfig.shared.indicatorLineWidth;

    final path = Path();
    path.moveTo(validPoints[0].dx, validPoints[0].dy);

    for (int i = 1; i < validPoints.length; i++) {
      path.lineTo(validPoints[i].dx, validPoints[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant KLineMainPainter oldDelegate) {
    return oldDelegate.datas != datas ||
        oldDelegate.positionDatas != positionDatas ||
        oldDelegate.maxPrice != maxPrice ||
        oldDelegate.minPrice != minPrice ||
        oldDelegate.mainChartIndicatorSelection != mainChartIndicatorSelection;
  }
}

/// 交叉网格线绘制器
class CrossGridPainter extends CustomPainter {
  final double topHeight;
  final double bottomHeight;
  final int horLineCount;
  final int verticalLineCount;
  final double lineWidth;
  final Color lineColor;
  final List<String> horLineTexts;
  final List<String> verticalLineTexts;

  CrossGridPainter({
    required this.topHeight,
    required this.bottomHeight,
    required this.horLineCount,
    required this.verticalLineCount,
    required this.lineWidth,
    required this.lineColor,
    required this.horLineTexts,
    required this.verticalLineTexts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = lineWidth
          ..style = PaintingStyle.stroke;

    final offset = lineWidth / 2.0;

    // 绘制顶部边界线
    canvas.drawLine(
      Offset(offset, offset),
      Offset(size.width - offset, offset),
      paint,
    );

    final itemHeight =
        (size.height - topHeight - bottomHeight - offset) / (horLineCount - 1);
    final itemWidth = (size.width - offset * 2) / (verticalLineCount - 1);
    double lastY = topHeight;

    // 绘制横线和价格标签
    for (int i = 0; i < horLineCount; i++) {
      canvas.drawLine(
        Offset(offset, lastY),
        Offset(size.width - offset, lastY),
        paint,
      );
      // 绘制价格标签
      if (i < horLineTexts.length) {
        _drawText(
          canvas,
          horLineTexts[i],
          Offset(size.width - 50, i == 0 ? lastY + lineWidth : lastY - 12),
          lineColor,
        );
      }

      lastY += itemHeight;
    }

    // 绘制底部边界线
    canvas.drawLine(
      Offset(offset, size.height - offset),
      Offset(size.width - offset, size.height - offset),
      paint,
    );

    double lastX = offset;

    // 绘制竖线和时间标签
    for (int i = 0; i < verticalLineCount; i++) {
      canvas.drawLine(
        Offset(lastX, offset),
        Offset(lastX, size.height - bottomHeight - offset),
        paint,
      );

      // 绘制时间标签
      if (i < verticalLineTexts.length) {
        _drawText(
          canvas,
          verticalLineTexts[i],
          Offset(lastX - 20, size.height - (bottomHeight + 12) / 2 - offset),
          lineColor,
        );
      }

      lastX += itemWidth;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CrossGridPainter oldDelegate) {
    return oldDelegate.horLineTexts != horLineTexts ||
        oldDelegate.verticalLineTexts != verticalLineTexts;
  }
}

/// 十字线绘制器
class CrossLinePainter extends CustomPainter {
  final Offset point;
  final Size containerSize;
  final double verticalLineTopY;
  final double verticalLineBottomY;
  final double horizontalLineLeftX;
  final double horizontalLineRightX;
  final Color crossLineColor;
  final double crossLineWidth;
  final KLineModel? selectedKLineModel;
  final double bottomHeight;

  CrossLinePainter({
    required this.point,
    required this.containerSize,
    required this.verticalLineTopY,
    required this.verticalLineBottomY,
    required this.horizontalLineLeftX,
    required this.horizontalLineRightX,
    required this.crossLineColor,
    required this.crossLineWidth,
    this.selectedKLineModel,
    required this.bottomHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = crossLineColor
          ..strokeWidth = crossLineWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // 计算日期标签frame
    Rect? dateLabelFrame;
    if (selectedKLineModel != null) {
      final dateString = selectedKLineModel!.dateString;
      final textPainter = TextPainter(
        text: TextSpan(text: dateString, style: const TextStyle(fontSize: 10)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      const padding = 4.0;
      final labelWidth = textPainter.width + padding * 2;
      final labelHeight = bottomHeight;
      final labelX = point.dx - labelWidth / 2;
      final labelY = containerSize.height - bottomHeight;

      dateLabelFrame = Rect.fromLTWH(labelX, labelY, labelWidth, labelHeight);
    }

    // 绘制垂直线（在日期标签处断开）
    if (dateLabelFrame != null &&
        point.dx >= dateLabelFrame.left &&
        point.dx <= dateLabelFrame.right) {
      // 上半部分
      canvas.drawLine(
        Offset(point.dx, verticalLineTopY),
        Offset(point.dx, dateLabelFrame.top),
        paint,
      );
      // 下半部分
      canvas.drawLine(
        Offset(point.dx, dateLabelFrame.bottom),
        Offset(point.dx, verticalLineBottomY),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(point.dx, verticalLineTopY),
        Offset(point.dx, verticalLineBottomY),
        paint,
      );
    }

    // 绘制水平线
    canvas.drawLine(
      Offset(horizontalLineLeftX, point.dy),
      Offset(horizontalLineRightX, point.dy),
      paint,
    );

    // 绘制圆点
    final dotPaint =
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 3, dotPaint);

    final dotBorderPaint =
        Paint()
          ..color = crossLineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawCircle(point, 3, dotBorderPaint);

    // 绘制日期标签
    if (dateLabelFrame != null && selectedKLineModel != null) {
      // 绘制背景
      final bgPaint =
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
      canvas.drawRect(dateLabelFrame, bgPaint);

      final borderPaint =
          Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;
      canvas.drawRect(dateLabelFrame, borderPaint);

      // 绘制文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: selectedKLineModel!.dateString,
          style: const TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          dateLabelFrame.left + 4,
          dateLabelFrame.top + (dateLabelFrame.height - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CrossLinePainter oldDelegate) {
    return oldDelegate.point != point ||
        oldDelegate.selectedKLineModel != selectedKLineModel;
  }
}
