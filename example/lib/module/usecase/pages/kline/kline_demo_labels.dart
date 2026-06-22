// ignore_for_file: file_names

// K 线 Demo 指标标签：负责主图和副图左上角的指标数值展示。
part of 'KLineDemoPage.dart';

/// 主图指标标签，跟随当前选中 K 线展示 MA/EMA/BOLL 数值。
class _MainIndicatorLabels extends StatelessWidget {
  const _MainIndicatorLabels({required this.context, required this.selected});

  final KLineChartContext<KLineModel> context;
  final KLineModel selected;

  @override
  Widget build(BuildContext context) {
    final indicators = selected.kLineTechnicalIndicatorsModel;
    if (indicators == null) return const SizedBox.shrink();
    final active = this.context.controller.activeIndicatorIds;
    return Positioned(
      left: 12,
      top: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.contains(KLineTechnicalIndicatorType.ma.name))
            _row([
              ('MA5', indicators.ma5, this.context.theme.indicatorColorAt(0)),
              ('MA10', indicators.ma10, this.context.theme.indicatorColorAt(1)),
              ('MA30', indicators.ma30, this.context.theme.indicatorColorAt(2)),
            ]),
          if (active.contains(KLineTechnicalIndicatorType.ema.name))
            _row([
              ('EMA5', indicators.ema5, this.context.theme.indicatorColorAt(3)),
              (
                'EMA10',
                indicators.ema10,
                this.context.theme.indicatorColorAt(4),
              ),
              (
                'EMA30',
                indicators.ema30,
                this.context.theme.indicatorColorAt(5),
              ),
            ]),
          if (active.contains(KLineTechnicalIndicatorType.boll.name))
            _row([
              (
                'UPPER',
                indicators.bollUpper,
                this.context.theme.indicatorColorAt(0),
              ),
              (
                'MB',
                indicators.bollMiddle,
                this.context.theme.indicatorColorAt(1),
              ),
              (
                'LOWER',
                indicators.bollLower,
                this.context.theme.indicatorColorAt(2),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _row(List<(String, double?, Color)> values) {
    final children = values
        .where((value) => value.$2 != null)
        .map(
          (value) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: Text(
              '${value.$1}:${value.$2!.toStringAsFixed(2)}',
              style: TextStyle(color: value.$3, fontSize: 9),
            ),
          ),
        )
        .toList();
    if (children.isEmpty) return const SizedBox.shrink();
    return Row(children: children);
  }
}

/// 副图指标标签，按启用副图的顺序定位到每个副图左上角。
class _SecondaryIndicatorLabels extends StatelessWidget {
  const _SecondaryIndicatorLabels({
    required this.context,
    required this.selected,
  });

  final KLineChartContext<KLineModel> context;
  final KLineModel selected;

  @override
  Widget build(BuildContext context) {
    final indicators = selected.kLineTechnicalIndicatorsModel;
    if (indicators == null) return const SizedBox.shrink();
    final activeTypes = KLineTechnicalIndicatorType.secondTypes
        .where(
          (type) =>
              this.context.controller.activeIndicatorIds.contains(type.name),
        )
        .toList();
    return Stack(
      children: [
        for (var i = 0; i < activeTypes.length; i++)
          Positioned(
            left: 12,
            top:
                this.context.layout.mainChartHeight +
                this.context.layout.secondaryPaneHeight * i +
                5,
            child: _label(activeTypes[i], indicators),
          ),
      ],
    );
  }

  Widget _label(
    KLineTechnicalIndicatorType type,
    KLineTechnicalIndicatorsModel indicators,
  ) {
    switch (type) {
      case KLineTechnicalIndicatorType.volume:
        return _row('VOL:', [
          ('MA5', indicators.volumeMA5),
          ('MA10', indicators.volumeMA10),
        ]);
      case KLineTechnicalIndicatorType.macd:
        return _row('MACD:', [
          ('DIF', indicators.dif),
          ('DEA', indicators.dea),
          ('MACD', indicators.macd),
        ]);
      case KLineTechnicalIndicatorType.kdj:
        return _row('KDJ:', [
          ('K', indicators.k),
          ('D', indicators.d),
          ('J', indicators.j),
        ]);
      case KLineTechnicalIndicatorType.rsi:
        return _row('RSI:', [
          ('RSI6', indicators.rsi6),
          ('RSI12', indicators.rsi12),
          ('RSI24', indicators.rsi24),
        ]);
      case KLineTechnicalIndicatorType.wr:
        return _row('WR:', [
          ('WR6', indicators.wr6),
          ('WR10', indicators.wr10),
          ('WR14', indicators.wr14),
        ]);
      case KLineTechnicalIndicatorType.ma:
      case KLineTechnicalIndicatorType.ema:
      case KLineTechnicalIndicatorType.boll:
        return const SizedBox.shrink();
    }
  }

  Widget _row(String title, List<(String, double?)> values) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 8, color: Colors.blue)),
        for (final value in values)
          if (value.$2 != null)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                '${value.$1}:${value.$2!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 8, color: Colors.black54),
              ),
            ),
      ],
    );
  }
}
