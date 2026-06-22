import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoCubit.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineResponse.dart';

void main() {
  test('start emits cached data before refreshed remote data', () async {
    final repository = _MemoryRepository();
    await repository.setValue<String, Map<String, dynamic>>(
      'kline.demo.15min',
      {
        'data': [_sampleData(id: 1, close: 11).toJson()],
      },
    );
    final store = KlineStore.withLoader(
      preferenceRepositoryPort: repository,
      dataLoader: (_, _) async => [_sampleData(id: 2, close: 12)],
    );
    final cubit = KLineDemoCubit(klineStore: store);
    final states = <KLineDemoState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.start();
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(states[0].isLoading, isTrue);
    expect(states[1].data.first.close, 11);
    expect(states[1].isLoading, isTrue);
    expect(states.last.data.first.close, 12);
    expect(states.last.isLoading, isFalse);
    expect(cubit.state.data.first.close, 12);
    await cubit.close();
  });

  test('selectPeriod clears current data and loads selected period', () async {
    final store = KlineStore.withLoader(
      preferenceRepositoryPort: _MemoryRepository(),
      dataLoader: (_, _) async => [_sampleData(id: 3, close: 13)],
    );
    final cubit = KLineDemoCubit(klineStore: store);

    await cubit.selectPeriod(KLinePeriod.day1);

    expect(cubit.state.selectedPeriod, KLinePeriod.day1);
    expect(cubit.state.data.first.close, 13);
    expect(cubit.state.isLoading, isFalse);
    await cubit.close();
  });
}

KLineData _sampleData({required int id, required double close}) {
  return KLineData(
    id: id,
    open: 10,
    close: close,
    low: 9,
    high: 13,
    amount: 1000,
    vol: 100,
    count: 10,
  );
}

class _MemoryRepository extends Repository {
  _MemoryRepository() : super('memory');

  final _values = <Object?, Object?>{};

  @override
  Future<void> setValue<K, V>(K key, V? value) async {
    _values[key] = value;
  }

  @override
  Future<V?> getValue<K, V>(K key) async {
    return _values[key] as V?;
  }

  @override
  Future<void> delete<K>(K key) async {
    _values.remove(key);
  }
}
