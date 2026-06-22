import 'package:flutter/material.dart';

@immutable
class KLineTheme {
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

  final Color candleUpColor;
  final Color candleDownColor;
  final Color gridLineColor;
  final Color crosshairColor;
  final Color backgroundColor;
  final Color textColor;
  final List<Color> indicatorColors;
  final double candleStrokeWidth;
  final double indicatorStrokeWidth;
  final double gridStrokeWidth;

  Color indicatorColorAt(int index) {
    if (indicatorColors.isEmpty) return textColor;
    return indicatorColors[index % indicatorColors.length];
  }

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

@immutable
class KLineLayoutConfig {
  const KLineLayoutConfig({
    this.candleWidth = 8.5,
    this.candleSpacing = 2,
    this.mainChartHeight = 340,
    this.secondaryPaneHeight = 70,
    this.indicatorSelectorHeight = 40,
    this.gridHorizontalCount = 5,
    this.gridVerticalCount = 6,
    this.contentPadding = const EdgeInsets.fromLTRB(2, 30, 2, 30),
    this.chartPadding = const EdgeInsets.symmetric(horizontal: 2),
    this.minScale = 0.5,
    this.maxScale = 3,
  });

  final double candleWidth;
  final double candleSpacing;
  final double mainChartHeight;
  final double secondaryPaneHeight;
  final double indicatorSelectorHeight;
  final int gridHorizontalCount;
  final int gridVerticalCount;
  final EdgeInsets contentPadding;
  final EdgeInsets chartPadding;
  final double minScale;
  final double maxScale;

  double scaledCandleWidth(double scale) => candleWidth * scale;
  double scaledCandleSpacing(double scale) => candleSpacing * scale;

  double contentHeightForMainChart() {
    return mainChartHeight - contentPadding.vertical;
  }

  double chartHeight({
    int secondaryPaneCount = 0,
    bool includeSelector = true,
  }) {
    return mainChartHeight +
        secondaryPaneHeight * secondaryPaneCount +
        (includeSelector ? indicatorSelectorHeight : 0);
  }
}

@immutable
class KLineBehaviorConfig {
  const KLineBehaviorConfig({
    this.enableScale = true,
    this.enableCrosshair = true,
    this.keepCrosshairOnLongPressEnd = true,
    this.clearSelectionOnScroll = true,
  });

  final bool enableScale;
  final bool enableCrosshair;
  final bool keepCrosshairOnLongPressEnd;
  final bool clearSelectionOnScroll;
}
