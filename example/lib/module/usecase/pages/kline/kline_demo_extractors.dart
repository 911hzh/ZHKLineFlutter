// ignore_for_file: file_names

// K 线 Demo 指标取值器：为不同指标线提供统一的数值读取入口。
part of 'KLineDemoPage.dart';

/// 将指标枚举映射到 KLineTechnicalIndicatorsModel 上的具体字段。
enum _IndicatorValueExtractor {
  ma5,
  ma10,
  ma30,
  ema5,
  ema10,
  ema30,
  bollUpper,
  bollMiddle,
  bollLower,
  macd,
  dif,
  dea,
  k,
  d,
  j,
  rsi6,
  rsi12,
  rsi24,
  wr6,
  wr10,
  wr14,
  volumeMA5,
  volumeMA10;

  double? value(KLineTechnicalIndicatorsModel? model) {
    if (model == null) return null;
    return switch (this) {
      ma5 => model.ma5,
      ma10 => model.ma10,
      ma30 => model.ma30,
      ema5 => model.ema5,
      ema10 => model.ema10,
      ema30 => model.ema30,
      bollUpper => model.bollUpper,
      bollMiddle => model.bollMiddle,
      bollLower => model.bollLower,
      macd => model.macd,
      dif => model.dif,
      dea => model.dea,
      k => model.k,
      d => model.d,
      j => model.j,
      rsi6 => model.rsi6,
      rsi12 => model.rsi12,
      rsi24 => model.rsi24,
      wr6 => model.wr6,
      wr10 => model.wr10,
      wr14 => model.wr14,
      volumeMA5 => model.volumeMA5,
      volumeMA10 => model.volumeMA10,
    };
  }
}
