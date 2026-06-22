// ignore_for_file: file_names

import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';
import 'package:injectable/injectable.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineResponse.dart';

/// K 线网络接口，统一走 example 工程注册的 RestClient。
@lazySingleton
class KlineApi {
  KlineApi({required this.client});

  final RestClient client;

  /// 获取火币 K 线历史数据。
  Future<List<KLineData>> fetchKLineData({
    required String symbol,
    required KLinePeriod period,
    required int size,
  }) async {
    final response = await client
        .get(
          '/market/history/kline',
          queryParameters: {
            'period': period.value,
            'size': size,
            'symbol': symbol,
          },
        )
        .toModel(KLineResponse.fromJson);
    return response.data.data;
  }
}
