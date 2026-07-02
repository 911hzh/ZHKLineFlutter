import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomThemeLayoutPage extends StatelessWidget {
  const CustomThemeLayoutPage({super.key});

  static const routeName = '/kline/custom/theme-layout';

  @override
  Widget build(BuildContext context) {
    return const CustomKLineDemoShell(
      copy: CustomDemoCopy(
        title: '自定义主题与布局',
        description:
            '通过 KLineTheme、KLineLayoutConfig、KLineBehaviorConfig '
            '快速改变图表外观、尺寸和交互能力。',
        extensionPoint: 'KLineTheme / KLineLayoutConfig / KLineBehaviorConfig',
        scenario: '适合品牌换肤、暗色行情页、不同屏幕尺寸下的蜡烛宽度和副图高度调整。',
      ),
      backgroundColor: Color(0xFF101418),
      theme: KLineTheme(
        backgroundColor: Color(0xFF101418),
        gridLineColor: Color(0xFF28313A),
        crosshairColor: Color(0xFF8AA1B3),
        textColor: Color(0xFF9AA8B5),
        candleUpColor: Color(0xFFFF5C7A),
        candleDownColor: Color(0xFF00C087),
        indicatorColors: [
          Color(0xFFFFD166),
          Color(0xFF4CC9F0),
          Color(0xFFC77DFF),
          Color(0xFFFF9F1C),
          Color(0xFF7BD88F),
          Color(0xFFB8C0FF),
        ],
        candleStrokeWidth: 1.2,
        indicatorStrokeWidth: 1.4,
      ),
      layout: KLineLayoutConfig(
        candleWidth: 7.5,
        candleSpacing: 2.5,
        mainChartHeight: 360,
        secondaryPaneHeight: 84,
        indicatorSelectorHeight: 36,
        gridHorizontalCount: 6,
        gridVerticalCount: 5,
        minScale: 0.7,
        maxScale: 2.6,
      ),
      behavior: KLineBehaviorConfig(
        enableScale: true,
        enableCrosshair: true,
        keepCrosshairOnLongPressEnd: true,
      ),
      initialIndicators: ['ma', 'volume', 'macd'],
    );
  }
}
