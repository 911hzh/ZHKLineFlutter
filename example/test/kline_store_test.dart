import 'package:example/base/store/kline/KlineStore.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineResponse.dart';

void main() {
  test('readCached restores period data from user preferences', () async {
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

    final state = await store.readCached(KLinePeriod.min15);

    expect(state.period, KLinePeriod.min15);
    expect(state.models, hasLength(1));
    expect(state.models.first.close, 11);
  });

  test(
    'refresh fetches remote data and updates user preference cache',
    () async {
      final repository = _MemoryRepository();
      final store = KlineStore.withLoader(
        preferenceRepositoryPort: repository,
        dataLoader: (_, _) async => [_sampleData(id: 2, close: 12)],
      );

      final state = await store.refresh(KLinePeriod.min15);
      final cached = await repository.getValue<String, Map<String, dynamic>>(
        'kline.demo.15min',
      );

      expect(state.models, hasLength(1));
      expect(state.models.first.close, 12);
      expect((cached?['data'] as List).length, 1);
    },
  );
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
