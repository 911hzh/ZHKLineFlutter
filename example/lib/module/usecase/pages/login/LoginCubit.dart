import 'package:example/base/api/UserApi.dart';
import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginState {
  const LoginState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  final bool isLoading;
  final bool isSuccess;
  final Object? error;
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required UserApi userApi, required AuthStoreImpl authStore})
    : _userApi = userApi,
      _authStore = authStore,
      super(const LoginState());

  final UserApi _userApi;
  final AuthStoreImpl _authStore;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const LoginState(isLoading: true));
    try {
      final response = await _userApi.login(
        username: username,
        password: password,
      );
      await _authStore.loginWithToken(response.token, userId: response.userId);
      emit(const LoginState(isSuccess: true));
    } catch (error) {
      emit(LoginState(error: error));
    }
  }
}
