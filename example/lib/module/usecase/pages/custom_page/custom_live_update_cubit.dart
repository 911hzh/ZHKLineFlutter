import 'dart:async';
import 'dart:math';

import 'package:example/base/api/model/kline/KLinePeriod.dart';
import 'package:example/base/api/model/kline/KLineResponse.dart';
import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/base/util/DataUtil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CustomLiveScrollAction { none, latest, oldest, home }

class CustomLiveUpdateState {
  const CustomLiveUpdateState({
    this.period = KLinePeriod.min15,
    this.candles = const [],
    this.sourceCandles = const [],
    this.isLoading = false,
    this.error,
    this.isFollowingLatest = false,
    this.scrollAction = CustomLiveScrollAction.none,
    this.scrollRevision = 0,
    this.autoUpdateCount = 0,
  });

  final KLinePeriod period;
  final List<KLineModel> candles;
  final List<KLineModel> sourceCandles;
  final bool isLoading;
  final Object? error;
  final bool isFollowingLatest;
  final CustomLiveScrollAction scrollAction;
  final int scrollRevision;
  final int autoUpdateCount;

  CustomLiveUpdateState copyWith({
    KLinePeriod? period,
    List<KLineModel>? candles,
    List<KLineModel>? sourceCandles,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    bool? isFollowingLatest,
    CustomLiveScrollAction? scrollAction,
    bool bumpScrollRevision = false,
    int? autoUpdateCount,
  }) {
    return CustomLiveUpdateState(
      period: period ?? this.period,
      candles: candles ?? this.candles,
      sourceCandles: sourceCandles ?? this.sourceCandles,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isFollowingLatest: isFollowingLatest ?? this.isFollowingLatest,
      scrollAction: scrollAction ?? this.scrollAction,
      scrollRevision: bumpScrollRevision ? scrollRevision + 1 : scrollRevision,
      autoUpdateCount: autoUpdateCount ?? this.autoUpdateCount,
    );
  }
}

class CustomLiveUpdateCubit extends Cubit<CustomLiveUpdateState> {
  CustomLiveUpdateCubit({required KlineStore klineStore})
    : _klineStore = klineStore,
      super(const CustomLiveUpdateState());

  static const _autoUpdateInterval = Duration(seconds: 3);

  final KlineStore _klineStore;
  final _random = Random(7);
  Timer? _timer;
  var _hasLocalEdits = false;

  Future<void> start() async {
    await _load();
  }

  Future<void> retry() async {
    await _load();
  }

  void setFollowingLatest(bool value) {
    if (value) {
      if (_timer == null && state.candles.isNotEmpty) {
        _timer = Timer.periodic(
          _autoUpdateInterval,
          (_) => prependLatest(fromTimer: true),
        );
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
    if (state.isFollowingLatest == value) {
      return;
    }
    emit(state.copyWith(isFollowingLatest: value));
  }

  void prependLatest({bool fromTimer = false}) {
    if (state.candles.isEmpty) return;
    // timer 模拟 socket 推送：只有仍在跟随最新时，才自动把新 K 线滚回可见区。
    final shouldReveal = !fromTimer || state.isFollowingLatest;
    _hasLocalEdits = true;
    emit(
      state.copyWith(
        candles: _modelsForDisplay([
          _mockNeighborData(state.candles.first, newer: true),
          ..._rawData,
        ]),
        scrollAction: shouldReveal
            ? CustomLiveScrollAction.latest
            : CustomLiveScrollAction.none,
        bumpScrollRevision: shouldReveal,
        autoUpdateCount: fromTimer
            ? state.autoUpdateCount + 1
            : state.autoUpdateCount,
      ),
    );
  }

  void appendOlder() {
    if (state.candles.isEmpty) return;
    _hasLocalEdits = true;
    final next = _mockNeighborData(state.candles.last, newer: false);
    emit(
      state.copyWith(
        // 业务层决定旧数据追加到尾部；package 只接收最终列表和滚动请求。
        candles: _modelsForDisplay([..._rawData, next]),
        scrollAction: CustomLiveScrollAction.oldest,
        bumpScrollRevision: true,
      ),
    );
  }

  void replaceWindow() {
    if (state.sourceCandles.isEmpty) return;
    final start = min(8, max(0, state.sourceCandles.length - 1));
    final source = state.sourceCandles.skip(start).take(24).toList();
    _hasLocalEdits = true;
    emit(
      state.copyWith(
        candles: source.isEmpty ? state.sourceCandles : source,
        scrollAction: CustomLiveScrollAction.home,
        bumpScrollRevision: true,
      ),
    );
  }

  Future<void> _load() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final cached = await _klineStore.readCached(state.period);
    if (!isClosed && cached.models.isNotEmpty) {
      _applyRealData(cached);
    }

    try {
      final refreshed = await _klineStore.refresh(state.period);
      if (!isClosed) {
        _applyRealData(refreshed, isLoading: false);
      }
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: error));
      }
    }
  }

  void _applyRealData(KlineStoreState storeState, {bool isLoading = true}) {
    // 初始数据只来自真实 store；timer 是否启动只由“跟随最新数据”开关决定。
    emit(
      state.copyWith(
        period: storeState.period,
        sourceCandles: storeState.models,
        candles: _hasLocalEdits ? state.candles : storeState.models,
        isLoading: isLoading,
        clearError: true,
      ),
    );
  }

  List<KLineData> get _rawData {
    return state.candles.map((model) => model.klineData).toList();
  }

  List<KLineModel> _modelsForDisplay(List<KLineData> displayData) {
    final chronological = [...displayData]
      ..sort((left, right) => left.id.compareTo(right.id));
    // 插入/追加后统一重算指标，保证底部副图和主图指标跟随 demo 数据变化。
    return DataUtil.toKLineModelsWithIndicators(
      chronological,
      state.period,
    ).reversed.toList();
  }

  KLineData _mockNeighborData(KLineModel anchor, {required bool newer}) {
    final base = anchor.klineData;
    // 基于相邻真实 K 线做小幅波动，避免 demo 新数据看起来完全随机。
    final close = max(
      0.01,
      base.close * (1 + (_random.nextDouble() - 0.5) * 0.004),
    );
    final open = base.close;
    final shadow = base.close * (0.001 + _random.nextDouble() * 0.002);
    final high = max(open, close) + shadow;
    final low = max(0.01, min(open, close) - shadow);
    final volume = max(0.01, base.vol * (0.96 + _random.nextDouble() * 0.08));

    return KLineData(
      id: base.id + (newer ? 1 : -1) * _periodSeconds(state.period),
      open: open,
      close: close,
      low: low,
      high: high,
      amount: close * volume,
      vol: volume,
      count: max(1, (base.count * (0.95 + _random.nextDouble() * 0.1)).round()),
    );
  }

  int _periodSeconds(KLinePeriod period) {
    return switch (period) {
      KLinePeriod.min15 => 15 * 60,
      KLinePeriod.min60 => 60 * 60,
      KLinePeriod.hour4 => 4 * 60 * 60,
      KLinePeriod.day1 => 24 * 60 * 60,
      KLinePeriod.mon1 => 30 * 24 * 60 * 60,
    };
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
