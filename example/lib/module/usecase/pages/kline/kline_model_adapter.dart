// ignore_for_file: file_names

part of 'KLineDemoPage.dart';

class _KLineModelAdapter extends KLineDataAdapter<KLineModel> {
  const _KLineModelAdapter();

  @override
  double open(KLineModel item) => item.open;

  @override
  double high(KLineModel item) => item.high;

  @override
  double low(KLineModel item) => item.low;

  @override
  double close(KLineModel item) => item.close;

  @override
  double volume(KLineModel item) => item.volume;

  @override
  String dateLabel(KLineModel item) => item.dateString;

  @override
  double? indicatorValue(KLineModel item, String valueId) {
    final indicators = item.kLineTechnicalIndicatorsModel;
    if (indicators == null) return null;
    return switch (valueId) {
      KLineDefaultIndicators.ma5 => indicators.ma5,
      KLineDefaultIndicators.ma10 => indicators.ma10,
      KLineDefaultIndicators.ma30 => indicators.ma30,
      KLineDefaultIndicators.ema5 => indicators.ema5,
      KLineDefaultIndicators.ema10 => indicators.ema10,
      KLineDefaultIndicators.ema30 => indicators.ema30,
      KLineDefaultIndicators.bollUpper => indicators.bollUpper,
      KLineDefaultIndicators.bollMiddle => indicators.bollMiddle,
      KLineDefaultIndicators.bollLower => indicators.bollLower,
      KLineDefaultIndicators.macdValue => indicators.macd,
      KLineDefaultIndicators.dif => indicators.dif,
      KLineDefaultIndicators.dea => indicators.dea,
      KLineDefaultIndicators.k => indicators.k,
      KLineDefaultIndicators.d => indicators.d,
      KLineDefaultIndicators.j => indicators.j,
      KLineDefaultIndicators.rsi6 => indicators.rsi6,
      KLineDefaultIndicators.rsi12 => indicators.rsi12,
      KLineDefaultIndicators.rsi24 => indicators.rsi24,
      KLineDefaultIndicators.wr6 => indicators.wr6,
      KLineDefaultIndicators.wr10 => indicators.wr10,
      KLineDefaultIndicators.wr14 => indicators.wr14,
      KLineDefaultIndicators.volumeMA5 => indicators.volumeMA5,
      KLineDefaultIndicators.volumeMA10 => indicators.volumeMA10,
      _ => null,
    };
  }

  @override
  List<KLineDetailEntry> detailEntries(KLineModel item) {
    return [
      KLineDetailEntry('时间', item.dateString),
      KLineDetailEntry('开', item.open.toStringAsFixed(2)),
      KLineDetailEntry('高', item.high.toStringAsFixed(2)),
      KLineDetailEntry('低', item.low.toStringAsFixed(2)),
      KLineDetailEntry('收', item.close.toStringAsFixed(2)),
      KLineDetailEntry('涨跌额', _signedNumber(item.changeAmount)),
      KLineDetailEntry('涨跌幅', _signedPercent(item.changeRate)),
      KLineDetailEntry('成交量', item.volume.toStringAsFixed(2)),
    ];
  }

  String _signedNumber(double value) {
    return value >= 0
        ? '+${value.toStringAsFixed(2)}'
        : value.toStringAsFixed(2);
  }

  String _signedPercent(double value) {
    final percent = value * 100;
    return percent >= 0
        ? '+${percent.toStringAsFixed(2)}%'
        : '${percent.toStringAsFixed(2)}%';
  }
}
