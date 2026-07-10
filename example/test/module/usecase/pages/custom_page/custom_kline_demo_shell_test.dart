import 'package:example/base/api/model/kline/KLineResponse.dart';
import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
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

  testWidgets(
    'chartBuilder retries through shell actions without reading a BlocProvider',
    (tester) async {
      var requestCount = 0;
      final store = KlineStore.withLoader(
        preferenceRepositoryPort: _MemoryRepository(),
        dataLoader: (_, _) async {
          requestCount += 1;
          return [
            _sampleData(id: requestCount, close: requestCount.toDouble()),
          ];
        },
      );
      getIt.registerSingleton<KlineStore>(store);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomKLineDemoShell(
            copy: const CustomDemoCopy(
              title: '自定义 Shell',
              description: '测试 retry 由 shell 显式传递',
              extensionPoint: 'CustomKLineDemoActions',
              scenario: '自定义图表不依赖 BlocProvider 层级',
            ),
            chartBuilder:
                (context, state, controller, adapter, actions, onScroll) {
                  return TextButton(
                    key: const Key('custom-shell-retry-button'),
                    onPressed: actions.retry,
                    child: Text('retry ${state.data.length}'),
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(requestCount, 1);

      await tester.tap(find.byKey(const Key('custom-shell-retry-button')));
      await tester.pumpAndSettle();

      expect(requestCount, 2);
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
