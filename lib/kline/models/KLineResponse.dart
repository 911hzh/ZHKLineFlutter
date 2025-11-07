/// 火币API K线数据响应模型
class KLineResponse {
  /// 频道名称
  final String ch;

  /// 状态
  final String status;

  /// 时间戳
  final int ts;

  /// K线数据数组
  final List<KLineData> data;

  KLineResponse({required this.ch, required this.status, required this.ts, required this.data});

  factory KLineResponse.fromJson(Map<String, dynamic> json) {
    return KLineResponse(
      ch: json['ch'] as String,
      status: json['status'] as String,
      ts: json['ts'] as int,
      data: (json['data'] as List<dynamic>).map((item) => KLineData.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'ch': ch, 'status': status, 'ts': ts, 'data': data.map((item) => item.toJson()).toList()};
  }
}

/// 单个K线数据模型（对应API响应）
class KLineData {
  /// K线ID（时间戳）
  final int id;

  /// 开盘价
  final double open;

  /// 收盘价
  final double close;

  /// 最低价
  final double low;

  /// 最高价
  final double high;

  /// 成交额
  final double amount;

  /// 成交量（币）
  final double vol;

  /// 成交笔数
  final int count;

  KLineData({
    required this.id,
    required this.open,
    required this.close,
    required this.low,
    required this.high,
    required this.amount,
    required this.vol,
    required this.count,
  });

  factory KLineData.fromJson(Map<String, dynamic> json) {
    return KLineData(
      id: json['id'] as int,
      open: (json['open'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      vol: (json['vol'] as num).toDouble(),
      count: json['count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'open': open,
      'close': close,
      'low': low,
      'high': high,
      'amount': amount,
      'vol': vol,
      'count': count,
    };
  }
}
