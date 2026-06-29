/// 技术指标类型枚举
enum KLineTechnicalIndicatorType {
  ma, // 移动平均线
  ema, // 指数移动平均线
  boll, // 布林带
  macd, // MACD
  kdj, // KDJ
  rsi, // RSI
  wr, // 威廉指标
  volume // 成交量
  ;

  /// 主图技术指标类型
  static const List<KLineTechnicalIndicatorType> mainTypes = [
    KLineTechnicalIndicatorType.ma,
    KLineTechnicalIndicatorType.ema,
    KLineTechnicalIndicatorType.boll,
  ];

  /// 副图技术指标类型
  static const List<KLineTechnicalIndicatorType> secondTypes = [
    KLineTechnicalIndicatorType.volume,
    KLineTechnicalIndicatorType.macd,
    KLineTechnicalIndicatorType.kdj,
    KLineTechnicalIndicatorType.rsi,
    KLineTechnicalIndicatorType.wr,
  ];

  /// 是否为主图指标
  bool get isMainType => mainTypes.contains(this);

  /// 是否为副图指标
  bool get isSecondType => secondTypes.contains(this);
}
