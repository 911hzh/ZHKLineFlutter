import 'package:example/base/api/KlineApi.dart';
import 'package:example/base/api/model/depth/DepthResponse.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeepChartDemoState {
  const DeepChartDemoState({
    this.bids = const [],
    this.asks = const [],
    this.isLoading = false,
    this.error,
  });

  final List<DepthLevel> bids;
  final List<DepthLevel> asks;
  final bool isLoading;
  final Object? error;

  DeepChartDemoState copyWith({
    List<DepthLevel>? bids,
    List<DepthLevel>? asks,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return DeepChartDemoState(
      bids: bids ?? this.bids,
      asks: asks ?? this.asks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class DeepChartDemoCubit extends Cubit<DeepChartDemoState> {
  DeepChartDemoCubit({required KlineApi api})
    : _api = api,
      super(const DeepChartDemoState());

  final KlineApi _api;

  Future<void> start() async {
    await _load(clearData: false);
  }

  Future<void> retry() async {
    await _load(clearData: state.bids.isEmpty && state.asks.isEmpty);
  }

  Future<void> _load({required bool clearData}) async {
    emit(
      state.copyWith(
        bids: clearData ? const [] : state.bids,
        asks: clearData ? const [] : state.asks,
        isLoading: true,
        clearError: true,
      ),
    );
    try {
      final depth = await _api.fetchMarketDepth(
        symbol: 'btcusdt',
        depth: 20,
        type: 'step0',
      );
      emit(
        state.copyWith(
          bids: depth.tick.bids,
          asks: depth.tick.asks,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, error: error));
    }
  }
}
