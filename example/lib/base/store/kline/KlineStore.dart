// ignore_for_file: file_names

import 'package:example/base/api/AppApiClient.dart';
import 'package:example/module/getIt/GetItInstanceName.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_foundation_kit/wcore/store/StoreBase.dart';
import 'package:injectable/injectable.dart';
import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/base/api/model/kline/KLinePeriod.dart';
import 'package:example/base/api/model/kline/KLineResponse.dart';
import 'package:example/base/util/DataUtil.dart';

typedef KlineDataLoader =
    Future<List<KLineData>> Function(KLinePeriod period, int size);

const _klineCachePrefix = 'kline.demo';
const _klineSymbol = 'btcusdt';
const _klineFetchSize = 50;

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
    required AppApiClient apiClient,
  }) : this.withLoader(
         preferenceRepositoryPort: preferenceRepositoryPort,
         dataLoader: (period, size) {
           return apiClient.klineApi.fetchKLineData(
             symbol: _klineSymbol,
             period: period,
             size: size,
           );
         },
       );

  KlineStore.withLoader({
    required Repository preferenceRepositoryPort,
    required KlineDataLoader dataLoader,
  }) : _preferenceRepositoryPort = preferenceRepositoryPort,
       _dataLoader = dataLoader,
       super(KlineStoreState.empty());

  final Repository _preferenceRepositoryPort;
  final KlineDataLoader _dataLoader;
  final _pages = <KLinePeriod, int>{};

  Future<KlineStoreState> readCached(KLinePeriod period) async {
    final cachedJson = await _preferenceRepositoryPort
        .getValue<String, Map<String, dynamic>>(
          _cacheKey(period, _klineFetchSize),
        );
    if (cachedJson == null) {
      return KlineStoreState.empty(period: period);
    }

    // 50 条缓存只代表首屏窗口；旧版本可能把 loadMore 后的 100 条写进来，
    // 读取时再裁剪一次，避免首屏直接拿到超出窗口的数据。
    final rawData = _latestWindow(
      _sortRawData(_rawDataFromJson(cachedJson)),
      _klineFetchSize,
    );
    final state = KlineStoreState(
      period: period,
      models: _modelsForDisplay(rawData, period),
      fromCache: true,
    );
    setState(state);
    return state;
  }

  Future<KlineStoreState> refresh(KLinePeriod period) async {
    _pages[period] = 1;
    return _fetchAndCache(period: period, size: _klineFetchSize);
  }

  Future<KlineStoreState> loadMore(KLinePeriod period) async {
    final nextPage = (_pages[period] ?? 1) + 1;
    final size = _klineFetchSize * nextPage;
    final state = await _fetchAndCache(period: period, size: size);
    _pages[period] = nextPage;
    return state;
  }

  Future<KlineStoreState> _fetchAndCache({
    required KLinePeriod period,
    required int size,
  }) async {
    final fetchedData = await _dataLoader(period, size);
    // API 已返回指定 size 的完整窗口；这里不能再合并当前内存数据，
    // 否则 refresh(50) 会把 loadMore 后的 100 条污染进 50 条缓存。
    final rawData = _latestWindow(_sortRawData(fetchedData), size);
    await _preferenceRepositoryPort.setValue<String, Map<String, dynamic>>(
      _cacheKey(period, size),
      {'data': rawData.map((item) => item.toJson()).toList()},
    );

    final nextState = KlineStoreState(
      period: period,
      models: _modelsForDisplay(rawData, period),
    );
    setState(nextState);
    return nextState;
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

  String _cacheKey(KLinePeriod period, int size) {
    return '$_klineCachePrefix.${period.value}.$size';
  }

  List<KLineData> _rawDataFromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(KLineData.fromJson)
        .toList();
  }

  List<KLineData> _sortRawData(List<KLineData> data) {
    return [...data]..sort((left, right) => left.id.compareTo(right.id));
  }

  List<KLineData> _latestWindow(List<KLineData> data, int size) {
    if (data.length <= size) return data;
    return data.sublist(data.length - size);
  }

  List<KLineModel> _modelsForDisplay(
    List<KLineData> rawData,
    KLinePeriod period,
  ) {
    final chronologicalModels = DataUtil.toKLineModelsWithIndicators(
      rawData,
      period,
    );
    return chronologicalModels.reversed.toList();
  }
}
