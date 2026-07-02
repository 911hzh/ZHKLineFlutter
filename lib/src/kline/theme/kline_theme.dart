import 'package:flutter/material.dart';

/// K 线图默认主题配置。
///
/// 该对象集中管理蜡烛、网格、十字线、背景、文字和指标线颜色，
/// 以及基础线宽。默认 delegate 会从这里读取绘制样式，业务方可以
/// 通过构造函数或 [copyWith] 覆盖局部样式。
@immutable
class KLineTheme {
  /// 创建一套 K 线图主题。
  const KLineTheme({
    this.candleUpColor = const Color(0xFFF14965),
    this.candleDownColor = const Color(0xFF00B066),
    this.gridLineColor = const Color(0xFFDFDFDF),
    this.crosshairColor = const Color(0xFFDFDFDF),
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF666666),
    this.indicatorColors = const [
      Color(0xFFFFD700),
      Color(0xFF00BFFF),
      Color(0xFFDA70D6),
      Color(0xFFFF8C00),
      Color(0xFF32CD32),
      Color(0xFF6666FF),
    ],
    this.candleStrokeWidth = 1,
    this.indicatorStrokeWidth = 1,
    this.gridStrokeWidth = 1,
  });

  /// 上涨蜡烛和上涨相关元素颜色。
  final Color candleUpColor;

  /// 下跌蜡烛和下跌相关元素颜色。
  final Color candleDownColor;

  /// 网格线颜色。
  final Color gridLineColor;

  /// 长按选中时十字线颜色。
  final Color crosshairColor;

  /// 图表背景颜色。
  final Color backgroundColor;

  /// 坐标轴、指标标题和普通说明文字颜色。
  final Color textColor;

  /// 指标线颜色列表。
  ///
  /// 默认实现会按下标循环取色，适合 MA、BOLL、MACD 等多条线展示。
  final List<Color> indicatorColors;

  /// 蜡烛图描边宽度。
  final double candleStrokeWidth;

  /// 指标线绘制宽度。
  final double indicatorStrokeWidth;

  /// 网格线绘制宽度。
  final double gridStrokeWidth;

  /// 根据指标下标返回对应颜色。
  ///
  /// 当 [indicatorColors] 为空时，会回退到 [textColor]。
  Color indicatorColorAt(int index) {
    if (indicatorColors.isEmpty) return textColor;
    return indicatorColors[index % indicatorColors.length];
  }

  /// 返回一份局部覆盖后的主题配置。
  KLineTheme copyWith({
    Color? candleUpColor,
    Color? candleDownColor,
    Color? gridLineColor,
    Color? crosshairColor,
    Color? backgroundColor,
    Color? textColor,
    List<Color>? indicatorColors,
    double? candleStrokeWidth,
    double? indicatorStrokeWidth,
    double? gridStrokeWidth,
  }) {
    return KLineTheme(
      candleUpColor: candleUpColor ?? this.candleUpColor,
      candleDownColor: candleDownColor ?? this.candleDownColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      crosshairColor: crosshairColor ?? this.crosshairColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      indicatorColors: indicatorColors ?? this.indicatorColors,
      candleStrokeWidth: candleStrokeWidth ?? this.candleStrokeWidth,
      indicatorStrokeWidth: indicatorStrokeWidth ?? this.indicatorStrokeWidth,
      gridStrokeWidth: gridStrokeWidth ?? this.gridStrokeWidth,
    );
  }
}

/// K 线图布局配置。
///
/// 该配置描述蜡烛宽度、间距、主图高度、副图高度、指标选择器高度、
/// 内容留白和缩放范围。默认 delegate 和 core chart 会用它计算可见区、
/// 坐标节点和整体图表高度。
@immutable
class KLineLayoutConfig {
  /// 创建一套 K 线布局配置。
  const KLineLayoutConfig({
    this.candleWidth = 8.5,
    this.candleSpacing = 2,
    this.mainChartHeight = 340,
    this.secondaryPaneHeight = 70,
    this.indicatorSelectorHeight = 40,
    this.secondaryContentVerticalPadding = 8,
    this.gridHorizontalCount = 5,
    this.gridVerticalCount = 6,
    this.contentPadding = const EdgeInsets.fromLTRB(2, 30, 2, 30),
    this.chartPadding = const EdgeInsets.symmetric(horizontal: 2),
    this.minScale = 0.5,
    this.maxScale = 3,
  });

  /// 单根蜡烛的基础宽度，实际宽度会再乘以 controller 中的缩放值。
  final double candleWidth;

  /// 蜡烛之间的基础间距，实际间距会再乘以 controller 中的缩放值。
  final double candleSpacing;

  /// 主图区域高度。
  final double mainChartHeight;

  /// 单个副图区域高度。
  final double secondaryPaneHeight;

  /// 副图指标选择器高度。
  final double indicatorSelectorHeight;

  /// 副图内容在垂直方向上的内部留白。
  final double secondaryContentVerticalPadding;

  /// 横向网格线数量。
  final int gridHorizontalCount;

  /// 纵向网格线数量。
  final int gridVerticalCount;

  /// 主图内容留白。
  ///
  /// 蜡烛、指标线和坐标文案会基于该留白计算可绘制区域。
  final EdgeInsets contentPadding;

  /// 图表整体左右留白。
  final EdgeInsets chartPadding;

  /// 允许的最小缩放比例。
  final double minScale;

  /// 允许的最大缩放比例。
  final double maxScale;

  /// 按缩放比例计算后的蜡烛宽度。
  double scaledCandleWidth(double scale) => candleWidth * scale;

  /// 按缩放比例计算后的蜡烛间距。
  double scaledCandleSpacing(double scale) => candleSpacing * scale;

  /// 主图扣除上下内容留白后的实际绘制高度。
  double contentHeightForMainChart() {
    return mainChartHeight - contentPadding.vertical;
  }

  /// 根据副图数量计算整体图表高度。
  ///
  /// [secondaryPaneCount] 表示当前展示的副图数量，
  /// [includeSelector] 控制是否把指标选择器高度计入总高度。
  double chartHeight({
    int secondaryPaneCount = 0,
    bool includeSelector = true,
  }) {
    return mainChartHeight +
        secondaryPaneHeight * secondaryPaneCount +
        (includeSelector ? indicatorSelectorHeight : 0);
  }
}

/// K 线图交互行为配置。
///
/// 用于控制缩放、十字线、长按结束后选中态保留，以及滚动时是否清除选中态。
@immutable
class KLineBehaviorConfig {
  /// 创建一套 K 线交互行为配置。
  const KLineBehaviorConfig({
    this.enableScale = true,
    this.enableCrosshair = true,
    this.keepCrosshairOnLongPressEnd = true,
    this.clearSelectionOnScroll = true,
  });

  /// 是否允许双指缩放。
  final bool enableScale;

  /// 是否允许长按展示十字线。
  final bool enableCrosshair;

  /// 长按结束后是否保留最后一次选中的十字线状态。
  final bool keepCrosshairOnLongPressEnd;

  /// 滚动图表时是否清除当前选中态。
  final bool clearSelectionOnScroll;
}
