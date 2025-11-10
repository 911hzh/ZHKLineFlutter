import 'package:flutter/material.dart';
import 'ColorExtension.dart';

/// K线配置类
class KLineConfig {
  // 单例模式
  static final KLineConfig shared = KLineConfig._internal();

  factory KLineConfig() {
    return shared;
  }

  KLineConfig._internal();

  // 缩放因子（静态变量，所有实例共享）
  static double scale = 1.0;

  // 蜡烛图基础属性（需要缩放）
  double get candleWidth => _baseCandleWidth * scale;
  double get candleSpace => _baseCandleSpace * scale;
  final double _baseCandleWidth = 8.5;
  final double _baseCandleSpace = 2.0;

  // 不需要缩放的属性
  final double crossLineWidth = 1.0;
  final double candleMidleLineWidth = 1.0;
  final Color crossLineColor = ColorExtension.fromHex("#DFDFDF");
  final int crossHorCount = 5;
  final int crossVerticalCount = 6;
  final double crossTopHeight = 30.0;
  final double crossItemHeight = 70.0;

  // 蜡烛颜色配置
  final Color candleUpColor = ColorExtension.fromHex("#F14965"); // 上涨蜡烛颜色（阳线）
  final Color candleDownColor = ColorExtension.fromHex("#00B066"); // 下跌蜡烛颜色（阴线）
  final Color candleWickColor = ColorExtension.fromHex("#666666"); // 影线颜色

  // 技术指标配置
  final double indicatorLineWidth = 1.0; // 技术指标线条宽度
  final double volumeBarWidthRatio = 1.0; // 成交量柱状图宽度比例
  final double macdBarWidthRatio = 0.6; // MACD柱状图宽度比例

  final EdgeInsets chartViewPadding = const EdgeInsets.fromLTRB(2, 0, 2, 0);

  // 主图技术指标颜色配置
  final Color ma5Color = ColorExtension.fromHex("#FFD700"); // MA5线颜色
  final Color ma10Color = ColorExtension.fromHex("#00BFFF"); // MA10线颜色
  final Color ma30Color = ColorExtension.fromHex("#DA70D6"); // MA30线颜色

  final Color ema5Color = ColorExtension.fromHex("#FF8C00"); // EMA5线颜色
  final Color ema10Color = ColorExtension.fromHex("#32CD32"); // EMA10线颜色
  final Color ema30Color = ColorExtension.fromHex("#9966CC"); // EMA30线颜色

  final Color bollUpperColor = ColorExtension.fromHex("#FF6666"); // BOLL上轨颜色
  final Color bollMiddleColor = ColorExtension.fromHex("#66CC66"); // BOLL中轨颜色
  final Color bollLowerColor = ColorExtension.fromHex("#6666FF"); // BOLL下轨颜色

  // 副图技术指标颜色配置
  // MACD颜色
  final Color macdDifColor = ColorExtension.fromHex("#00BFFF"); // MACD DIF线颜色
  final Color macdDeaColor = ColorExtension.fromHex("#FF8C00"); // MACD DEA线颜色

  // KDJ颜色
  final Color kdjKColor = ColorExtension.fromHex("#00BFFF"); // KDJ K线颜色
  final Color kdjDColor = ColorExtension.fromHex("#FF8C00"); // KDJ D线颜色
  final Color kdjJColor = ColorExtension.fromHex("#DA70D6"); // KDJ J线颜色

  // RSI颜色
  final Color rsi6Color = ColorExtension.fromHex("#FF4500"); // RSI6线颜色
  final Color rsi12Color = ColorExtension.fromHex("#32CD32"); // RSI12线颜色
  final Color rsi24Color = ColorExtension.fromHex("#00BFFF"); // RSI24线颜色

  // WR颜色
  final Color wr6Color = ColorExtension.fromHex("#FF4500"); // WR6线颜色
  final Color wr10Color = ColorExtension.fromHex("#32CD32"); // WR10线颜色
  final Color wr14Color = ColorExtension.fromHex("#00BFFF"); // WR14线颜色

  // VOL颜色
  final Color volumeMA5Color = ColorExtension.fromHex("#00BFFF"); // 成交量MA5线颜色
  final Color volumeMA10Color = ColorExtension.fromHex("#FF8C00"); // 成交量MA10线颜色

  // 技术指标文字颜色配置
  final Color indicatorTextColor = ColorExtension.fromHex("#666666");
  final Color indicatorTextBackgroundColor = ColorExtension.fromHex("#F5F5F5");

  final double indicatorTypeControlHeight = 40.0;

  /// 蜡烛图的边距
  final EdgeInsets crandleInsets = const EdgeInsets.fromLTRB(2, 30, 2, 30);

  /// 获取整个KLineView的高度（主图+副图+指标控制条高度）
  /// 参考Swift版本：mainCanvasHeight + seconedHeight + indicatorTypeControlHeight
  double getAllHeight(List<dynamic> indicatorTypes) {
    final seconedHeight = getSecoendHeight(indicatorTypes);
    return mainCanvasHeight + seconedHeight + indicatorTypeControlHeight;
  }

  /// 获取副图的高度
  double getSecoendHeight(List<dynamic> indicatorTypes) {
    // 需要副图的指标类型
    final needSeconed = ['macd', 'kdj', 'rsi', 'wr', 'volume'];

    final seconedTypes =
        indicatorTypes
            .where(
              (type) => needSeconed.contains(type.toString().split('.').last),
            )
            .toList();
    final seconedHeight = crossItemHeight * seconedTypes.length;
    return seconedHeight;
  }

  /// 获取indicatorView的Y坐标
  double getIndicatorControlMinY(List<dynamic> indicatorTypes) {
    return getAllHeight(indicatorTypes) - indicatorTypeControlHeight;
  }

  /// 获取主图的高度
  double get mainCanvasHeight {
    return (crossHorCount - 1) * crossItemHeight +
        crandleInsets.bottom +
        crandleInsets.top +
        chartViewPadding.bottom +
        chartViewPadding.left;
  }
}
