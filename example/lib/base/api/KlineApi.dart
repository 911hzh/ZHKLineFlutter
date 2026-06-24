// ignore_for_file: file_names

import 'package:example/base/api/model/depth/DepthResponse.dart';
import 'package:example/base/api/model/kline/KLinePeriod.dart';
import 'package:example/base/api/model/kline/KLineResponse.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';
import 'package:injectable/injectable.dart';

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

  /// 获取火币市场深度快照。
  Future<DepthResponse> fetchMarketDepth({
    required String symbol,
    int depth = 20,
    String type = 'step0',
  }) async {
    final response = await client
        .get(
          '/market/depth',
          queryParameters: {'symbol': symbol, 'depth': depth, 'type': type},
        )
        .toModel(DepthResponse.fromJson);
    return response.data;
  }
}
