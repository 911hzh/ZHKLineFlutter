import 'dart:ui';

/// 单个K线对应的技术指标位置
class SingleIndicatorPosition {
  // MARK: - 主图指标位置

  // MA指标位置
  Offset? ma5Point;
  Offset? ma10Point;
  Offset? ma30Point;

  // EMA指标位置
  Offset? ema5Point;
  Offset? ema10Point;
  Offset? ema30Point;

  // BOLL指标位置
  Offset? bollUpperPoint;
  Offset? bollMiddlePoint;
  Offset? bollLowerPoint;

  SingleIndicatorPosition({
    this.ma5Point,
    this.ma10Point,
    this.ma30Point,
    this.ema5Point,
    this.ema10Point,
    this.ema30Point,
    this.bollUpperPoint,
    this.bollMiddlePoint,
    this.bollLowerPoint,
  });
}

/// K线位置信息模型
class KLinePositionModel {
  // MARK: - 基础位置属性

  /// 蜡烛图在图表中的X坐标（中心线位置）
  final double candleCenterX;

  /// 蜡烛图的宽度
  final double candleWidth;

  /// 蜡烛实体的顶部Y坐标
  final double candleBodyTopY;

  /// 蜡烛实体的底部Y坐标
  final double candleBodyBottomY;

  /// 蜡烛上影线的顶部Y坐标
  final double candleUpperWickTopY;

  /// 蜡烛下影线的底部Y坐标
  final double candleLowerWickBottomY;

  /// 当前K线对应的技术指标位置信息
  final SingleIndicatorPosition? indicatorPosition;

  KLinePositionModel({
    required this.candleCenterX,
    required this.candleWidth,
    required this.candleBodyTopY,
    required this.candleBodyBottomY,
    required this.candleUpperWickTopY,
    required this.candleLowerWickBottomY,
    this.indicatorPosition,
  });

  // MARK: - 计算属性

  /// 获取蜡烛图实体的矩形框
  Rect get candleBodyRect {
    final x = candleCenterX - candleWidth / 2;
    final y =
        candleBodyTopY < candleBodyBottomY ? candleBodyTopY : candleBodyBottomY;
    final height = (candleBodyTopY - candleBodyBottomY).abs();
    return Rect.fromLTWH(x, y, candleWidth, height);
  }

  /// 获取蜡烛图左边界X坐标
  double get candleLeftX => candleCenterX - candleWidth / 2;

  /// 获取蜡烛图右边界X坐标
  double get candleRightX => candleCenterX + candleWidth / 2;

  /// 获取蜡烛图frame
  Rect get candleFrame {
    return Rect.fromLTWH(
      candleCenterX - (candleWidth / 2),
      candleBodyTopY,
      candleWidth,
      candleBodyTopY - candleBodyBottomY,
    );
  }

  /// 获取上影线的中心点
  Offset get upperWickCenter => Offset(candleCenterX, candleUpperWickTopY);

  /// 获取下影线的中心点
  Offset get lowerWickPoint => Offset(candleCenterX, candleLowerWickBottomY);

  /// 获取蜡烛图整体的边界矩形
  Rect get candleBounds {
    final x = candleLeftX;
    final y = candleUpperWickTopY;
    final width = candleWidth;
    final height = candleLowerWickBottomY - candleUpperWickTopY;
    return Rect.fromLTWH(x, y, width, height);
  }

  /// 获取蜡烛图中心点
  Offset get candleCenter {
    final centerY = (candleUpperWickTopY + candleLowerWickBottomY) / 2;
    return Offset(candleCenterX, centerY);
  }

  // MARK: - 方法

  /// 判断给定的点是否在蜡烛图范围内
  bool containsPoint(Offset point) {
    final xInRange = point.dx >= candleLeftX && point.dx <= candleRightX;
    final yInRange =
        point.dy >= candleUpperWickTopY && point.dy <= candleLowerWickBottomY;
    return xInRange && yInRange;
  }

  /// 判断给定的点是否在蜡烛实体范围内
  bool containsPointInBody(Offset point) {
    return candleBodyRect.contains(point);
  }

  /// 判断给定的点是否在上影线范围内
  bool containsPointInUpperWick(Offset point) {
    final xInRange = (point.dx - candleCenterX).abs() <= 1.0; // 允许1像素的误差
    final topY =
        candleBodyTopY < candleBodyBottomY ? candleBodyTopY : candleBodyBottomY;
    final yInRange = point.dy >= candleUpperWickTopY && point.dy <= topY;
    return xInRange && yInRange;
  }

  /// 判断给定的点是否在下影线范围内
  bool containsPointInLowerWick(Offset point) {
    final xInRange = (point.dx - candleCenterX).abs() <= 1.0; // 允许1像素的误差
    final bottomY =
        candleBodyTopY > candleBodyBottomY ? candleBodyTopY : candleBodyBottomY;
    final yInRange = point.dy >= bottomY && point.dy <= candleLowerWickBottomY;
    return xInRange && yInRange;
  }

  /// 计算到指定点的距离
  double distanceToPoint(Offset point) {
    final center = candleCenter;
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return (dx * dx + dy * dy).abs();
  }

  /// 判断是否与另一个位置模型相交
  bool intersects(KLinePositionModel other) {
    return candleBounds.overlaps(other.candleBounds);
  }
}
