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
    'readCached exposes latest data first while keeping cache sortable',
    () async {
      final repository = _MemoryRepository();
      await repository.setValue<String, Map<String, dynamic>>(
        'kline.demo.15min',
        {
          'data': [
            _sampleData(id: 3, close: 13).toJson(),
            _sampleData(id: 1, close: 11).toJson(),
            _sampleData(id: 2, close: 12).toJson(),
          ],
        },
      );
      final store = KlineStore.withLoader(
        preferenceRepositoryPort: repository,
        dataLoader: (_, _) async => const [],
      );

      final state = await store.readCached(KLinePeriod.min15);

      expect(state.models.map((model) => model.timestamp), [3, 2, 1]);
    },
  );

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

  test('refresh sorts remote data and stores sorted cache', () async {
    final repository = _MemoryRepository();
    final store = KlineStore.withLoader(
      preferenceRepositoryPort: repository,
      dataLoader: (_, _) async => [
        _sampleData(id: 3, close: 13),
        _sampleData(id: 1, close: 11),
        _sampleData(id: 2, close: 12),
      ],
    );

    final state = await store.refresh(KLinePeriod.min15);
    final cached = await repository.getValue<String, Map<String, dynamic>>(
      'kline.demo.15min',
    );
    final cachedIds = (cached?['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map((json) => json['id'])
        .toList();

    expect(state.models.map((model) => model.timestamp), [3, 2, 1]);
    expect(cachedIds, [1, 2, 3]);
  });

  test('refresh merges fetched page with current cache by kline id', () async {
    final repository = _MemoryRepository();
    await repository.setValue<String, Map<String, dynamic>>(
      'kline.demo.15min',
      {
        'data': [
          _sampleData(id: 1, close: 11).toJson(),
          _sampleData(id: 2, close: 12).toJson(),
        ],
      },
    );
    final store = KlineStore.withLoader(
      preferenceRepositoryPort: repository,
      dataLoader: (_, _) async => [
        _sampleData(id: 2, close: 22),
        _sampleData(id: 3, close: 13),
      ],
    );

    final state = await store.refresh(KLinePeriod.min15);
    final cached = await repository.getValue<String, Map<String, dynamic>>(
      'kline.demo.15min',
    );
    final cachedIds = (cached?['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map((json) => json['id'])
        .toList();

    expect(state.models.map((model) => model.timestamp), [3, 2, 1]);
    expect(state.models.firstWhere((model) => model.timestamp == 2).close, 22);
    expect(cachedIds, [1, 2, 3]);
  });

  test('loadMore increments page and requests expanded size', () async {
    final requestedSizes = <int>[];
    final repository = _MemoryRepository();
    final store = KlineStore.withLoader(
      preferenceRepositoryPort: repository,
      dataLoader: (_, size) async {
        requestedSizes.add(size);
        return List.generate(
          size,
          (index) => _sampleData(id: index + 1, close: (index + 1).toDouble()),
        );
      },
    );

    await store.refresh(KLinePeriod.min15);
    final state = await store.loadMore(KLinePeriod.min15);

    expect(requestedSizes, [50, 100]);
    expect(state.models, hasLength(100));
    expect(state.models.first.timestamp, 100);
    expect(state.models.last.timestamp, 1);
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
