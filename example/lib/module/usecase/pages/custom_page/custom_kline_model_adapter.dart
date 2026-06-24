import 'package:example/base/api/models/KLineModel.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomKLineModelAdapter extends KLineDataAdapter<KLineModel> {
  const CustomKLineModelAdapter();

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
  double? indicatorValue(KLineModel item, KLineDefaultIndicatorValue value) {
    final indicators = item.kLineTechnicalIndicatorsModel;
    if (indicators == null) return null;
    return switch (value) {
      KLineDefaultIndicatorValue.ma5 => indicators.ma5,
      KLineDefaultIndicatorValue.ma10 => indicators.ma10,
      KLineDefaultIndicatorValue.ma30 => indicators.ma30,
      KLineDefaultIndicatorValue.ema5 => indicators.ema5,
      KLineDefaultIndicatorValue.ema10 => indicators.ema10,
      KLineDefaultIndicatorValue.ema30 => indicators.ema30,
      KLineDefaultIndicatorValue.bollUpper => indicators.bollUpper,
      KLineDefaultIndicatorValue.bollMiddle => indicators.bollMiddle,
      KLineDefaultIndicatorValue.bollLower => indicators.bollLower,
      KLineDefaultIndicatorValue.macd => indicators.macd,
      KLineDefaultIndicatorValue.dif => indicators.dif,
      KLineDefaultIndicatorValue.dea => indicators.dea,
      KLineDefaultIndicatorValue.k => indicators.k,
      KLineDefaultIndicatorValue.d => indicators.d,
      KLineDefaultIndicatorValue.j => indicators.j,
      KLineDefaultIndicatorValue.rsi6 => indicators.rsi6,
      KLineDefaultIndicatorValue.rsi12 => indicators.rsi12,
      KLineDefaultIndicatorValue.rsi24 => indicators.rsi24,
      KLineDefaultIndicatorValue.wr6 => indicators.wr6,
      KLineDefaultIndicatorValue.wr10 => indicators.wr10,
      KLineDefaultIndicatorValue.wr14 => indicators.wr14,
      KLineDefaultIndicatorValue.volumeMA5 => indicators.volumeMA5,
      KLineDefaultIndicatorValue.volumeMA10 => indicators.volumeMA10,
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
      KLineDetailEntry('涨跌额', signedNumber(item.changeAmount)),
      KLineDetailEntry('涨跌幅', signedPercent(item.changeRate)),
      KLineDetailEntry('成交量', item.volume.toStringAsFixed(2)),
    ];
  }

  String signedNumber(double value) {
    return value >= 0
        ? '+${value.toStringAsFixed(2)}'
        : value.toStringAsFixed(2);
  }

  String signedPercent(double value) {
    final percent = value * 100;
    return percent >= 0
        ? '+${percent.toStringAsFixed(2)}%'
        : '${percent.toStringAsFixed(2)}%';
  }
}
