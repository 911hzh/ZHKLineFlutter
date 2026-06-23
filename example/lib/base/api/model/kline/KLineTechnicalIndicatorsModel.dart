/// 技术指标数据结构
class KLineTechnicalIndicatorsModel {
  // MA均线
  final double? ma5;
  final double? ma10;
  final double? ma30;

  // EMA指数移动平均线
  final double? ema5;
  final double? ema10;
  final double? ema30;

  // BOLL布林带
  final double? bollUpper;
  final double? bollMiddle;
  final double? bollLower;

  // MACD
  final double? macd;
  final double? dif;
  final double? dea;

  // KDJ
  final double? k;
  final double? d;
  final double? j;

  // RSI相对强弱指标
  final double? rsi6;
  final double? rsi12;
  final double? rsi24;

  // WR威廉指标
  final double? wr6;
  final double? wr10;
  final double? wr14;

  // 成交量相关
  final double? volumeMA5;
  final double? volumeMA10;

  KLineTechnicalIndicatorsModel({
    this.ma5,
    this.ma10,
    this.ma30,
    this.ema5,
    this.ema10,
    this.ema30,
    this.bollUpper,
    this.bollMiddle,
    this.bollLower,
    this.macd,
    this.dif,
    this.dea,
    this.k,
    this.d,
    this.j,
    this.rsi6,
    this.rsi12,
    this.rsi24,
    this.wr6,
    this.wr10,
    this.wr14,
    this.volumeMA5,
    this.volumeMA10,
  });
}
