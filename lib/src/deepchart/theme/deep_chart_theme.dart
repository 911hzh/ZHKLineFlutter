import 'package:flutter/material.dart';

/// 深度图默认 UI 的颜色和线宽配置。
///
/// 该配置只描述默认 delegate 的视觉样式；如果业务方完全替换
/// [DeepChartDelegate]，可以选择复用这些字段，也可以自行定义样式来源。
@immutable
class DeepChartTheme {
  /// 创建深度图主题配置。
  const DeepChartTheme({
    this.bidColor = const Color(0xFF00B066),
    this.askColor = const Color(0xFFF14965),
    this.gridLineColor = const Color(0xFFE8E8E8),
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF8A8A8A),
    this.watermarkColor = const Color(0x1A111827),
    this.lineStrokeWidth = 1.5,
    this.gridStrokeWidth = 1,
  });

  /// 买盘累计深度线和填充区域的主色。
  final Color bidColor;

  /// 卖盘累计深度线和填充区域的主色。
  final Color askColor;

  /// 图表内容区域内网格线颜色。
  final Color gridLineColor;

  /// 深度图背景色。
  final Color backgroundColor;

  /// 坐标轴、图例等辅助文字颜色。
  final Color textColor;

  /// 默认水印文字颜色。
  final Color watermarkColor;

  /// 买卖盘深度曲线线宽。
  final double lineStrokeWidth;

  /// 网格线线宽。
  final double gridStrokeWidth;
}

/// 深度图默认布局配置。
///
/// [mainHeight] 控制中间图形区域高度，[bottomHeight] 控制底部数字行高度。
/// 组件整体高度由二者相加得到；[contentPadding] 定义中间图形区域内的绘制边距。
@immutable
class DeepChartLayoutConfig {
  /// 创建深度图布局配置。
  const DeepChartLayoutConfig({
    this.mainHeight = 360,
    this.contentPadding = const EdgeInsets.fromLTRB(12, 34, 12, 28),
    this.centerGap = 2,
    this.gridHorizontalCount = 5,
    this.gridVerticalCount = 4,
    this.priceLabelCount = 5,
    this.bottomHeight = 16,
  });

  /// 中间图形区域高度，不包含底部价格数字行。
  final double mainHeight;

  /// 中间图形区域内边距。
  ///
  /// 该内边距只作用于主绘图区。底部文本行会额外读取 bottom padding，
  /// 用于给文字到底部边界保留距离。
  final EdgeInsets contentPadding;

  /// 买盘和卖盘在中轴线两侧保留的间距。
  final double centerGap;

  /// 横向网格分段数量。
  final int gridHorizontalCount;

  /// 纵向网格分段数量。
  final int gridVerticalCount;

  /// 底部价格标签数量。
  final int priceLabelCount;

  /// 底部价格标签独立行高度。
  final double bottomHeight;

  /// 根据组件尺寸计算实际绘制内容区域。
  Rect contentRectFor(Size size) {
    return Rect.fromLTRB(
      contentPadding.left,
      contentPadding.top,
      size.width - contentPadding.right,
      mainHeight - contentPadding.bottom,
    );
  }
}
