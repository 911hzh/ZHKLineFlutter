// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:example/base/api/AppApiClient.dart' as _i225;
import 'package:example/base/api/AppNetworkProxy.dart' as _i808;
import 'package:example/base/api/AppRestClientAdapter.dart' as _i1032;
import 'package:example/base/api/UserApi.dart' as _i1064;
import 'package:example/base/store/auth/AuthStoreImpl.dart' as _i798;
import 'package:example/base/store/kline/KlineStore.dart' as _i316;
import 'package:example/base/store/settings/Settings.dart' as _i1025;
import 'package:example/base/store/settings/SettingsStore.dart' as _i213;
import 'package:example/base/store/user/UserStoreImpl.dart' as _i154;
import 'package:example/module/getIt/RegisterModule.dart' as _i352;
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart' as _i698;
import 'package:flutter_foundation_kit/wcore/Repository.dart' as _i38;
import 'package:flutter_foundation_kit/wcore/settings/SettingsLoader.dart'
    as _i248;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i698.Repository>(
      () => registerModule.userPreferenceRepository(),
      instanceName: 'userPreferenceRepository',
    );
    gh.lazySingleton<_i248.SettingsLoader>(
      () => _i1025.DefaultSettingsLoader(),
    );
    gh.lazySingleton<_i698.Repository>(
      () => registerModule.authRepository(),
      instanceName: 'authRepository',
    );
    gh.lazySingleton<_i698.NetworkProxy>(() => _i808.AppNetworkProxy());
    gh.lazySingleton<_i213.SettingsStore>(
      () => _i213.SettingsStore(settingsLoader: gh<_i248.SettingsLoader>()),
    );
    gh.lazySingleton<_i798.AuthStoreImpl>(
      () => _i798.AuthStoreImpl(
        keychainPort: gh<_i38.Repository>(instanceName: 'authRepository'),
      ),
    );
    gh.lazySingleton<_i316.KlineStore>(
      () => _i316.KlineStore(
        preferenceRepositoryPort: gh<_i38.Repository>(
          instanceName: 'userPreferenceRepository',
        ),
      ),
    );
    gh.lazySingleton<_i698.RestClientAdapter>(
      () =>
          _i1032.AppRestClientAdapter(settingsStore: gh<_i213.SettingsStore>()),
    );
    gh.lazySingleton<_i698.RestClient>(
      () => registerModule.restClient(
        gh<_i698.RestClientAdapter>(),
        gh<_i698.NetworkProxy>(),
      ),
    );
    gh.lazySingleton<_i1064.UserApi>(
      () => _i1064.UserApi(client: gh<_i698.RestClient>()),
    );
    gh.lazySingleton<_i225.AppApiClient>(
      () => _i225.AppApiClient(userApi: gh<_i1064.UserApi>()),
    );
    gh.lazySingleton<_i154.UserStoreImpl>(
      () => _i154.UserStoreImpl(
        apiClient: gh<_i225.AppApiClient>(),
        authStore: gh<_i798.AuthStoreImpl>(),
        preferenceRepositoryPort: gh<_i38.Repository>(
          instanceName: 'userPreferenceRepository',
        ),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i352.RegisterModule {}
