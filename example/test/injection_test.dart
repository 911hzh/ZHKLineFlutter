import 'package:example/base/api/AppApiClient.dart';
import 'package:example/base/api/KlineApi.dart';
import 'package:example/base/api/UserApi.dart';
import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:example/base/store/kline/KlineStore.dart';
import 'package:example/base/store/settings/SettingsStore.dart';
import 'package:example/base/store/user/UserStoreImpl.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('resolves registered dependencies', () {
    final apiClient = getIt<AppApiClient>();

    expect(apiClient.userApi, same(getIt<UserApi>()));
    expect(apiClient.klineApi, same(getIt<KlineApi>()));
    expect(getIt<SettingsStore>(), isA<SettingsStore>());
    expect(getIt<AuthStoreImpl>(), isA<AuthStoreImpl>());
    expect(getIt<UserStoreImpl>(), isA<UserStoreImpl>());
    expect(getIt<KlineStore>(), isA<KlineStore>());
  });
}
