import 'dart:math' as math;

import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomCoreChartPage extends StatelessWidget {
  const CustomCoreChartPage({super.key});

  static const routeName = '/kline/custom/core-chart';

  @override
  Widget build(BuildContext context) {
    return CustomKLineDemoShell(
      copy: const CustomDemoCopy(
        title: '完全自定义核心图表',
        description:
            '直接使用 KLineChart 和 KLineChartDelegate，可以完全跳过默认 UI，自己定义图表高度、布局节点、绘制和选中浮层。',
        extensionPoint: 'KLineChart<T> / KLineChartDelegate<T>',
        scenario: '适合分时图、极简走势图、特殊金融图表，或需要完全自定义绘制协议的业务。',
      ),
      chartBuilder: (context, state, controller, adapter, actions, onScroll) {
        if (state.isLoading && state.data.isEmpty) {
          return const SizedBox(
            height: 360,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.error != null && state.data.isEmpty) {
          return SizedBox(
            height: 220,
            child: Center(child: Text('加载失败: ${state.error}')),
          );
        }
        return KLineChart<KLineModel>(
          controller: controller,
          dataSource: state.data,
          delegate: _CoreLineChartDelegate(
            adapter: adapter,
            onScroll: onScroll,
          ),
          layout: const KLineLayoutConfig(
            candleWidth: 6,
            candleSpacing: 2,
            mainChartHeight: 360,
            contentPadding: EdgeInsets.fromLTRB(12, 28, 12, 28),
          ),
          theme: const KLineTheme(
            gridLineColor: Color(0xFFE2E8F0),
            textColor: Color(0xFF64748B),
            indicatorColors: [Color(0xFF2563EB)],
          ),
          behavior: const KLineBehaviorConfig(clearSelectionOnScroll: false),
        );
      },
    );
  }
}

class _CoreLineChartDelegate extends KLineChartDelegate<KLineModel> {
  const _CoreLineChartDelegate({required this.adapter, required this.onScroll});

  final KLineDataAdapter<KLineModel> adapter;
  final void Function(KLineChartContext<KLineModel>, KLineScrollMetrics)
  onScroll;

  @override
  double chartHeight(KLineChartContext<KLineModel> context) {
    return context.layout.mainChartHeight;
  }

  @override
  void drawGrid(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    final paint = Paint()
      ..color = context.theme.gridLineColor
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y =
          context.layout.contentPadding.top +
          context.layout.contentHeightForMainChart() * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Core Delegate Line Chart',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(12, 6));
  }

  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<KLineModel> context,
  ) {
    if (context.layoutNodes.length < 2) return;
    final range = _visibleCloseRange(context);
    final rect = Rect.fromLTWH(
      0,
      context.layout.contentPadding.top,
      size.width,
      context.layout.contentHeightForMainChart(),
    );
    final path = Path();
    for (var i = 0; i < context.layoutNodes.length; i++) {
      final node = context.layoutNodes[i];
      final point = Offset(
        node.centerX,
        _valueToY(adapter.close(node.item), range, rect),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    final paint = Paint()
      ..color = context.theme.indicatorColorAt(0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(context.layoutNodes.last.centerX, rect.bottom)
      ..lineTo(context.layoutNodes.first.centerX, rect.bottom)
      ..close();
    final fillPaint = Paint()
      ..color = context.theme.indicatorColorAt(0).withValues(alpha: 0.08);
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<KLineModel> chartContext,
    KLineLayoutNode<KLineModel> selectedNode,
  ) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xEE0F172A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            '自定义 selection: ${adapter.dateLabel(selectedNode.item)} close=${adapter.close(selectedNode.item).toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  @override
  void didScroll(
    KLineChartContext<KLineModel> context,
    KLineScrollMetrics metrics,
  ) {
    onScroll(context, metrics);
  }

  (double min, double max) _visibleCloseRange(
    KLineChartContext<KLineModel> context,
  ) {
    var minValue = double.infinity;
    var maxValue = -double.infinity;
    for (final node in context.layoutNodes) {
      minValue = math.min(minValue, adapter.close(node.item));
      maxValue = math.max(maxValue, adapter.close(node.item));
    }
    if (minValue == maxValue) {
      return (minValue - 1, maxValue + 1);
    }
    final padding = (maxValue - minValue) * 0.12;
    return (minValue - padding, maxValue + padding);
  }

  double _valueToY(double value, (double min, double max) range, Rect rect) {
    final span = range.$2 - range.$1;
    if (span == 0) return rect.center.dy;
    final ratio = (value - range.$1) / span;
    return rect.bottom - rect.height * ratio;
  }
}
