import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomGridPage extends StatelessWidget {
  const CustomGridPage({super.key});

  static const routeName = '/kline/custom/grid';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '自定义网格与辅助线',
        description: '覆盖 drawGrid 可以在固定视口层追加不会随横向滚动移动的价格线、水印、风控线或坐标轴标识。',
        extensionPoint: 'KLineChartDelegate.drawGrid',
        scenario: '适合标记开盘价、预警价、清算价、交易区间或品牌水印。',
      ),
      delegateBuilder: (adapter, onScroll) {
        return _CustomGridDelegate(adapter: adapter, onScroll: onScroll);
      },
    );
  }
}

class _CustomGridDelegate extends KLineDefaultDelegateImpl<KLineModel> {
  const _CustomGridDelegate({required super.adapter, super.onScroll});

  @override
  void drawGrid(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    super.drawGrid(canvas, size, context);
    _drawAlertLine(canvas, size, context);
    _drawWatermark(canvas, size);
  }

  void _drawAlertLine(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final y =
        context.layout.contentPadding.top +
        context.layout.contentHeightForMainChart() * 0.38;
    final paint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '自定义预警价线',
        style: TextStyle(
          color: Color(0xFFFF9800),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 12, y - 18),
    );
  }

  void _drawWatermark(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ZHKLine Custom Grid',
        style: TextStyle(
          color: Color(0x142196F3),
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, 142),
    );
  }
}
