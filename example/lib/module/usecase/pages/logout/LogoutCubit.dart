import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogoutState {
  const LogoutState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  final bool isLoading;
  final bool isSuccess;
  final Object? error;
}

class LogoutCubit extends Cubit<LogoutState> {
  LogoutCubit({required AuthStoreImpl authStore})
    : _authStore = authStore,
      super(const LogoutState());

  final AuthStoreImpl _authStore;

  Future<void> logout() async {
    emit(const LogoutState(isLoading: true));
    try {
      await _authStore.logout();
      emit(const LogoutState(isSuccess: true));
    } catch (error) {
      emit(LogoutState(error: error));
    }
  }
}
