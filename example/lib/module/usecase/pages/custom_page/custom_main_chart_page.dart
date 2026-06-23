import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:k_line_flutter/k_line_flutter.dart';

class CustomMainChartPage extends StatelessWidget {
  const CustomMainChartPage({super.key});

  static const routeName = '/kline/custom/main-chart';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '自定义主图绘制',
        description: '覆盖 drawMainChart 可以保留默认蜡烛与指标，同时追加订单线、持仓成本线、成交标记或策略信号。',
        extensionPoint: 'KLineChartDelegate.drawMainChart',
        scenario: '适合交易页展示委托价、平均持仓成本、买卖点和策略信号。',
      ),
      initialIndicators: const ['ma', 'volume'],
      delegateBuilder: (adapter, onScroll) {
        return _CustomMainChartDelegate(adapter: adapter, onScroll: onScroll);
      },
    );
  }
}

class _CustomMainChartDelegate extends KLineDefaultDelegateImpl<KLineModel> {
  const _CustomMainChartDelegate({required super.adapter, super.onScroll});

  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    super.drawMainChart(canvas, size, context);
    _drawOrderLine(canvas, size, context);
  }

  void _drawOrderLine(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final contentTop = context.layout.contentPadding.top;
    final contentHeight = context.layout.contentHeightForMainChart();
    final y = contentTop + contentHeight * 0.62;
    final paint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final labelPainter = TextPainter(
      text: const TextSpan(
        text: '委托价 / 成本线',
        style: TextStyle(
          color: Color(0xFF7C3AED),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      Offset(context.controller.scrollOffset + 12, y - 20),
    );

    final markerPaint = Paint()..color = const Color(0xFF7C3AED);
    for (final node in context.layoutNodes.take(3)) {
      canvas.drawCircle(Offset(node.centerX, y), 3.5, markerPaint);
    }
  }
}
