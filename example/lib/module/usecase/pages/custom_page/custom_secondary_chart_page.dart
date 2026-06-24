import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomSecondaryChartPage extends StatelessWidget {
  const CustomSecondaryChartPage({super.key});

  static const routeName = '/kline/custom/secondary-chart';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '自定义副图绘制',
        description:
            '覆盖 drawSecondaryCharts 可以保留默认 VOL/MACD/KDJ/RSI/WR，同时追加自己的区间、阈值线或说明标签。',
        extensionPoint: 'KLineChartDelegate.drawSecondaryCharts',
        scenario: '适合展示资金费率、风险区间、成交量阈值、策略评分或业务自定义副图。',
      ),
      initialIndicators: const ['volume', 'macd'],
      delegateBuilder: (adapter, onScroll) {
        return _CustomSecondaryChartDelegate(
          adapter: adapter,
          onScroll: onScroll,
        );
      },
    );
  }
}

class _CustomSecondaryChartDelegate
    extends KLineDefaultDelegateImpl<KLineModel> {
  const _CustomSecondaryChartDelegate({required super.adapter, super.onScroll});

  @override
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    super.drawSecondaryCharts(canvas, size, context);
    _drawRiskBand(canvas, size, context);
  }

  void _drawRiskBand(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final top = context.layout.mainChartHeight + 12;
    final height = context.layout.secondaryPaneHeight - 32;
    if (height <= 0) return;

    final bandPaint = Paint()..color = const Color(0x2214B8A6);
    final bandRect = Rect.fromLTWH(
      0,
      top + height * 0.25,
      size.width,
      height * 0.25,
    );
    canvas.drawRect(bandRect, bandPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF14B8A6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, bandRect.top),
      Offset(size.width, bandRect.top),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, bandRect.bottom),
      Offset(size.width, bandRect.bottom),
      linePaint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '自定义副图风险区间',
        style: TextStyle(
          color: Color(0xFF0F766E),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(context.controller.scrollOffset + 12, bandRect.top - 15),
    );
  }
}
