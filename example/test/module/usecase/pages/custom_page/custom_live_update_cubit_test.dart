import 'package:example/base/api/model/kline/KLineResponse.dart';
import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/usecase/pages/custom_page/custom_live_update_cubit.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'start loads store data and timer updates only reveal while following',
    () async {
      final store = KlineStore.withLoader(
        preferenceRepositoryPort: _MemoryRepository(),
        dataLoader: (_, size) async {
          return List.generate(
            size,
            (index) =>
                _sampleData(id: 1000 + index, close: (100 + index).toDouble()),
          );
        },
      );
      final cubit = CustomLiveUpdateCubit(klineStore: store);

      await cubit.start();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.candles, hasLength(50));
      expect(cubit.state.isFollowingLatest, isFalse);

      cubit.prependLatest(fromTimer: true);

      expect(cubit.state.autoUpdateCount, 1);
      expect(cubit.state.scrollAction, CustomLiveScrollAction.none);
      expect(cubit.state.scrollRevision, 0);

      cubit.setFollowingLatest(true);
      cubit.prependLatest(fromTimer: true);

      expect(cubit.state.isFollowingLatest, isTrue);
      expect(cubit.state.autoUpdateCount, 2);
      expect(cubit.state.scrollAction, CustomLiveScrollAction.latest);
      expect(cubit.state.scrollRevision, 1);

      await cubit.close();
    },
  );
}

KLineData _sampleData({required int id, required double close}) {
  return KLineData(
    id: id,
    open: close - 1,
    close: close,
    low: close - 2,
    high: close + 2,
    amount: close * 100,
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
