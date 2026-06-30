import 'package:example/base/api/model/kline/KLineResponse.dart';
import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/custom_page/custom_live_update_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('live update demo loads data and applies timer updates', (
    tester,
  ) async {
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
    getIt.registerSingleton<KlineStore>(store);

    await tester.pumpWidget(const MaterialApp(home: CustomLiveUpdatePage()));
    await tester.pumpAndSettle();

    expect(find.text('跟随最新数据'), findsOneWidget);
    expect(find.textContaining('items 50'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.textContaining('auto 1'), findsOneWidget);
    expect(find.textContaining('items 51'), findsOneWidget);
  });
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
