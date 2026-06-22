import 'package:example/base/store/kline/KlineStore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';

class KLineDemoState {
  const KLineDemoState({
    this.selectedPeriod = KLinePeriod.min15,
    this.data = const [],
    this.isLoading = false,
    this.error,
  });

  final KLinePeriod selectedPeriod;
  final List<KLineModel> data;
  final bool isLoading;
  final Object? error;

  KLineDemoState copyWith({
    KLinePeriod? selectedPeriod,
    List<KLineModel>? data,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return KLineDemoState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class KLineDemoCubit extends Cubit<KLineDemoState> {
  KLineDemoCubit({required KlineStore klineStore})
    : _klineStore = klineStore,
      super(const KLineDemoState());

  final KlineStore _klineStore;

  Future<void> start() async {
    await _load(state.selectedPeriod, clearData: false);
  }

  Future<void> selectPeriod(KLinePeriod period) async {
    if (period == state.selectedPeriod) return;
    await _load(period, clearData: true);
  }

  Future<void> retry() async {
    await _load(state.selectedPeriod, clearData: state.data.isEmpty);
  }

  Future<void> _load(KLinePeriod period, {required bool clearData}) async {
    emit(
      state.copyWith(
        selectedPeriod: period,
        data: clearData ? const [] : state.data,
        isLoading: true,
        clearError: true,
      ),
    );

    final cachedState = await _klineStore.readCached(period);
    if (cachedState.models.isNotEmpty) {
      emit(
        state.copyWith(
          selectedPeriod: period,
          data: cachedState.models,
          isLoading: true,
          clearError: true,
        ),
      );
    }

    try {
      final refreshedState = await _klineStore.refresh(period);
      emit(
        state.copyWith(
          selectedPeriod: period,
          data: refreshedState.models,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(selectedPeriod: period, isLoading: false, error: error),
      );
    }
  }
}
