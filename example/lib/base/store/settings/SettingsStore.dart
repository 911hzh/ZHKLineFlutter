import 'package:example/base/store/settings/Settings.dart';
import 'package:flutter_foundation_kit/cutil/Lazyload.dart';
import 'package:flutter_foundation_kit/wcore/settings/AppEnvironment.dart';
import 'package:flutter_foundation_kit/wcore/settings/SettingsLoader.dart';
import 'package:flutter_foundation_kit/wcore/store/StoreBase.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SettingsStore extends StoreBase<Settings> {
  SettingsStore({required SettingsLoader settingsLoader})
    : _settingsLoader = settingsLoader,
      super(
        Settings(
          environment: AppEnvironment.development,
          packageName: "",
          baseUrl: "https://api.huobi.pro",
        ),
      ) {
    settingsLazyload = Lazyload<Settings>(() async {
      final settings = await _settingsLoader.getSettings(
        builder: Settings.fromJson,
      );
      setState(settings);
      return settings;
    });
    get();
  }

  late final Lazyload<Settings> settingsLazyload;
  final SettingsLoader _settingsLoader;

  @override
  Future<Settings> get() async {
    return await settingsLazyload.get();
  }

  @override
  void dirty() {}

  @override
  void renew() {}
}
