import 'package:example/module/getIt/GetItInstanceName.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_foundation_kit/wcore/store/StoreBase.dart';
import 'package:injectable/injectable.dart';
import 'package:k_line_flutter/kline/api/KlineApi.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineResponse.dart';
import 'package:k_line_flutter/kline/utils/DataUtil.dart';

typedef KlineDataLoader =
    Future<List<KLineData>> Function(KLinePeriod period, int size);

const _klineCachePrefix = 'kline.demo';
const _klineSymbol = 'btcusdt';
const _klineFetchSize = 2000;

class KlineStoreState {
  const KlineStoreState({
    required this.period,
    required this.models,
    this.fromCache = false,
  });

  factory KlineStoreState.empty({KLinePeriod period = KLinePeriod.min15}) {
    return KlineStoreState(period: period, models: const []);
  }

  final KLinePeriod period;
  final List<KLineModel> models;
  final bool fromCache;
}

@lazySingleton
class KlineStore extends StoreBase<KlineStoreState> {
  KlineStore({
    @Named(RepositoryGetItInstanceName.userPreference)
    required Repository preferenceRepositoryPort,
  }) : this.withLoader(
         preferenceRepositoryPort: preferenceRepositoryPort,
         dataLoader: _defaultDataLoader,
       );

  KlineStore.withLoader({
    required Repository preferenceRepositoryPort,
    required KlineDataLoader dataLoader,
  }) : _preferenceRepositoryPort = preferenceRepositoryPort,
       _dataLoader = dataLoader,
       super(KlineStoreState.empty());

  final Repository _preferenceRepositoryPort;
  final KlineDataLoader _dataLoader;

  Future<KlineStoreState> readCached(KLinePeriod period) async {
    final cachedJson = await _preferenceRepositoryPort
        .getValue<String, Map<String, dynamic>>(_cacheKey(period));
    if (cachedJson == null) {
      return KlineStoreState.empty(period: period);
    }

    final rawData = _rawDataFromJson(cachedJson);
    final state = KlineStoreState(
      period: period,
      models: DataUtil.toKLineModelsWithIndicators(rawData, period),
      fromCache: true,
    );
    setState(state);
    return state;
  }

  Future<KlineStoreState> refresh(KLinePeriod period) async {
    final rawData = await _dataLoader(period, _klineFetchSize);
    await _preferenceRepositoryPort.setValue<String, Map<String, dynamic>>(
      _cacheKey(period),
      {'data': rawData.map((item) => item.toJson()).toList()},
    );

    final state = KlineStoreState(
      period: period,
      models: DataUtil.toKLineModelsWithIndicators(rawData, period),
    );
    setState(state);
    return state;
  }

  @override
  Future<KlineStoreState> get() async {
    final cached = await readCached(state.period);
    if (cached.models.isNotEmpty) return cached;
    return refresh(state.period);
  }

  @override
  void dirty() {
    setState(KlineStoreState.empty(period: state.period));
  }

  @override
  void renew() {
    refresh(state.period);
  }

  String _cacheKey(KLinePeriod period) => '$_klineCachePrefix.${period.value}';

  List<KLineData> _rawDataFromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(KLineData.fromJson)
        .toList();
  }

  static Future<List<KLineData>> _defaultDataLoader(
    KLinePeriod period,
    int size,
  ) async {
    final result = await KlineApi.shared.getBatchKLineData(
      symbols: const [_klineSymbol],
      period: period,
      size: size,
    );
    return result[_klineSymbol] ?? const [];
  }
}
