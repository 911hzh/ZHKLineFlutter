import 'package:k_line_flutter/kline/api/ApiClient.dart';
import 'package:k_line_flutter/kline/models/KLineResponse.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';

/// K线API接口类
class KlineApi {
  static final KlineApi shared = KlineApi._internal(apiClient: ApiClient(baseUrl: 'https://api.huobi.pro'));

  final ApiClient apiClient;

  /// 初始化K线API
  KlineApi._internal({required this.apiClient});

  /// 便利工厂构造函数
  factory KlineApi({String baseUrl = 'https://api.huobi.pro'}) {
    return KlineApi._internal(apiClient: ApiClient(baseUrl: baseUrl));
  }

  /// 获取K线历史数据
  Future<KLineResponse> getKLineHistory({required String symbol, required KLinePeriod period, int size = 200}) async {
    final path = '/market/history/kline?period=${period.value}&size=$size&symbol=$symbol';
    return await apiClient.getJson(path, KLineResponse.fromJson);
  }

  /// 获取K线历史数据并转换为KLineData数组
  Future<List<KLineData>> getKLineModels({required String symbol, required KLinePeriod period, int size = 200}) async {
    final response = await getKLineHistory(symbol: symbol, period: period, size: size);
    return response.data;
  }

  /// 获取实时K线数据
  Future<KLineData?> getLatestKLine({required String symbol, required KLinePeriod period}) async {
    final models = await getKLineModels(symbol: symbol, period: period, size: 1);
    return models.isNotEmpty ? models.first : null;
  }

  /// 批量获取多个交易对的K线数据
  Future<Map<String, List<KLineData>>> getBatchKLineData({
    required List<String> symbols,
    required KLinePeriod period,
    int size = 200,
  }) async {
    final result = <String, List<KLineData>>{};

    // 使用Future.wait并发获取数据
    final futures = symbols.map((symbol) async {
      final models = await getKLineModels(symbol: symbol, period: period, size: size);
      return (symbol, models);
    });

    final results = await Future.wait(futures);

    for (final (symbol, models) in results) {
      result[symbol] = models;
    }

    return result;
  }

  /// 泛型接口：获取指定类型的数据
  Future<T> fetchData<T>({required String path, required T Function(Map<String, dynamic>) fromJson}) async {
    return await apiClient.getJson(path, fromJson);
  }

  /// 泛型接口：根据参数构建请求获取数据
  Future<T> fetchDataWithParams<T>({
    required String endpoint,
    Map<String, String> parameters = const {},
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    String path = endpoint;

    if (parameters.isNotEmpty) {
      final queryItems = parameters.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
      path += '?$queryItems';
    }

    return await apiClient.getJson(path, fromJson);
  }
}
