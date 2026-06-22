import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:example/base/store/settings/SettingsStore.dart';
import 'package:example/base/store/settings/Settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StoreDemoState {
  const StoreDemoState({
    this.hasStarted = false,
    this.isLoading = false,
    this.settings,
    this.authState,
    this.error,
  });

  final bool hasStarted;
  final bool isLoading;
  final Settings? settings;
  final DemoAuthState? authState;
  final Object? error;
}

class StoreDemoCubit extends Cubit<StoreDemoState> {
  StoreDemoCubit({
    required SettingsStore settingsStore,
    required AuthStoreImpl authStore,
  }) : _settingsStore = settingsStore,
       _authStore = authStore,
       super(const StoreDemoState());

  final SettingsStore _settingsStore;
  final AuthStoreImpl _authStore;

  Future<void> load() async {
    emit(const StoreDemoState(hasStarted: true, isLoading: true));
    try {
      final settings = await _settingsStore.get();
      final authState = await _authStore.loginWithToken(
        'demo-token-${DateTime.now().millisecondsSinceEpoch}',
        userId: '1',
      );
      emit(
        StoreDemoState(
          hasStarted: true,
          settings: settings,
          authState: authState,
        ),
      );
    } catch (error) {
      emit(StoreDemoState(hasStarted: true, error: error));
    }
  }
}
