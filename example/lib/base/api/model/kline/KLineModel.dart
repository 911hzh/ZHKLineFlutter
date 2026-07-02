import 'package:intl/intl.dart';
import 'package:example/base/api/model/kline/KLinePeriod.dart';
import 'package:example/base/api/model/kline/KLineResponse.dart';
import 'package:example/base/api/model/kline/KLineTechnicalIndicatorsModel.dart';

/// K线数据模型
class KLineModel {
  /// 原始K线数据（组合引用）
  final KLineData klineData;

  /// 选中的周期
  final KLinePeriod selectedPeriod;

  /// 根据选中周期格式化的日期字符串
  final String dateString;

  /// 技术指标数据
  KLineTechnicalIndicatorsModel? kLineTechnicalIndicatorsModel;

  KLineModel({
    required this.klineData,
    required this.selectedPeriod,
    required this.dateString,
    // this.kLineTechnicalIndicatorsModel,
  });

  /// 工厂构造函数
  factory KLineModel.fromKLineData(
    KLineData klineData,
    KLinePeriod selectedPeriod,
  ) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      klineData.id * 1000,
      isUtc: false,
    );

    String dateString;
    final formatter = DateFormatter('Asia/Singapore');

    switch (selectedPeriod) {
      case KLinePeriod.min15:
      case KLinePeriod.min60:
      case KLinePeriod.hour4:
        // 短周期使用 "MM-dd HH:mm" 格式
        dateString = formatter.format(date, 'MM-dd HH:mm');
        break;
      default:
        // 其他情况使用 "yyyy-MM-dd" 格式
        dateString = formatter.format(date, 'yyyy-MM-dd');
    }

    return KLineModel(
      klineData: klineData,
      selectedPeriod: selectedPeriod,
      dateString: dateString,
    );
  }

  /// 便捷访问属性
  double get open => klineData.open;
  double get close => klineData.close;
  double get high => klineData.high;
  double get low => klineData.low;
  double get volume => klineData.vol;
  double get amount => klineData.amount;
  int get timestamp => klineData.id;

  /// 是否上涨
  bool get isRising => close > open;

  /// 涨跌幅
  double get changeRate {
    if (open == 0) return 0;
    return (close - open) / open;
  }

  /// 涨跌额
  double get changeAmount => close - open;
}

/// 日期格式化工具类
class DateFormatter {
  final String timeZone;

  DateFormatter(this.timeZone);

  String format(DateTime date, String pattern) {
    // 注意：Dart的DateTime已经考虑了时区，这里主要是格式化
    final formatter = DateFormat(pattern);
    return formatter.format(date);
  }
}
