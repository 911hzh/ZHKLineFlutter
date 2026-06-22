import 'package:example/base/store/settings/Settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';

class SettingsDemoState {
  const SettingsDemoState({
    this.hasStarted = false,
    this.isLoading = false,
    this.settings,
    this.error,
  });

  final bool hasStarted;
  final bool isLoading;
  final Settings? settings;
  final Object? error;
}

class SettingsDemoCubit extends Cubit<SettingsDemoState> {
  SettingsDemoCubit({required SettingsLoader settingsLoader})
    : _settingsLoader = settingsLoader,
      super(const SettingsDemoState());

  final SettingsLoader _settingsLoader;

  Future<void> load() async {
    emit(const SettingsDemoState(hasStarted: true, isLoading: true));
    try {
      final settings = await _settingsLoader.getSettings(
        builder: Settings.fromJson,
      );
      emit(SettingsDemoState(hasStarted: true, settings: settings));
    } catch (error) {
      emit(SettingsDemoState(hasStarted: true, error: error));
    }
  }
}
