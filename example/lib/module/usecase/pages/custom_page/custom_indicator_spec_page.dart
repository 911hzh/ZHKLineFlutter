import 'dart:math' as math;

import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomIndicatorSpecPage extends StatelessWidget {
  const CustomIndicatorSpecPage({super.key});

  static const routeName = '/kline/custom/indicator-spec';
  static const _cciId = 'custom.cci';
  static const _bodyPowerId = 'custom.bodyPower';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '动态指标定义',
        description:
            '通过 KLineIndicatorSpec 定义副图选择器。VOL 复用内置绘制，CCI 走默认折线绘制，特殊形态给 spec 传 renderer。',
        extensionPoint:
            'KLineWidget.secondaryIndicators / KLineIndicatorSpec.renderer',
        scenario: '适合接入 CCI、资金流、策略评分、风险强弱等业务自定义指标。',
      ),
      initialIndicators: const [
        KLineDefaultIndicators.volumeId,
        _cciId,
        _bodyPowerId,
      ],
      secondaryIndicators: [
        KLineDefaultIndicators.volume<KLineModel>(),
        const KLineIndicatorSpec<KLineModel>(
          id: _cciId,
          label: 'CCI',
          series: [
            KLineIndicatorSeries<KLineModel>(
              id: 'cci14',
              label: 'CCI14',
              colorIndex: 2,
              value: _cciValue,
            ),
          ],
        ),
        const KLineIndicatorSpec<KLineModel>(
          id: _bodyPowerId,
          label: '强弱',
          height: 76,
          renderer: _drawBodyPower,
          series: [
            KLineIndicatorSeries<KLineModel>(
              id: 'bodyPower',
              label: 'BODY',
              colorIndex: 0,
              value: _bodyPowerValue,
            ),
          ],
        ),
      ],
    );
  }
}

double? _cciValue(KLineModel item) {
  final span = math.max(0.01, item.high - item.low);
  return (item.close - (item.high + item.low + item.close) / 3) / span * 100;
}

double? _bodyPowerValue(KLineModel item) {
  final span = math.max(0.01, item.high - item.low);
  return (item.close - item.open) / span;
}

void _drawBodyPower(
  Canvas canvas,
  Rect rect,
  KLineChartContext<KLineModel> context,
  KLineDataAdapter<KLineModel> adapter,
  KLineIndicatorSpec<KLineModel> indicator,
) {
  final zeroY = rect.center.dy;
  final barWidth = math.max(
    1.0,
    context.layout.scaledCandleWidth(context.controller.scale) * 0.7,
  );
  final upPath = Path();
  final downPath = Path();

  for (final node in context.layoutNodes) {
    final value = _bodyPowerValue(node.item);
    if (value == null) continue;
    final height = (rect.height * 0.46 * value.abs()).clamp(
      1.0,
      rect.height / 2,
    );
    final top = value >= 0 ? zeroY - height : zeroY;
    final centerX = node.centerX + context.layout.chartPadding.left;
    final path = value >= 0 ? upPath : downPath;
    path.addRect(Rect.fromLTWH(centerX - barWidth / 2, top, barWidth, height));
  }

  final paint = Paint()..style = PaintingStyle.fill;
  canvas.drawPath(upPath, paint..color = context.theme.candleUpColor);
  canvas.drawPath(downPath, paint..color = context.theme.candleDownColor);

  final linePaint = Paint()
    ..color = context.theme.gridLineColor
    ..strokeWidth = 1;
  canvas.drawLine(
    Offset(rect.left, zeroY),
    Offset(rect.right, zeroY),
    linePaint,
  );
}
