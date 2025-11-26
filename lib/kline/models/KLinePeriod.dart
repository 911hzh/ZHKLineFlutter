/// K线周期枚举
enum KLinePeriod {
  min15('15min'),
  min60('60min'),
  hour4('4hour'),
  day1('1day'),
  mon1('1mon');

  final String value;
  const KLinePeriod(this.value);

  /// 获取所有周期
  static List<KLinePeriod> get allPeriods => KLinePeriod.values;
}
