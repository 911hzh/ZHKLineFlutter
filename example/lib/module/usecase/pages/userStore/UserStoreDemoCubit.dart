import 'package:example/base/store/user/UserStoreImpl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserStoreDemoState {
  const UserStoreDemoState({
    this.hasStarted = false,
    this.isLoading = false,
    this.userState,
    this.error,
  });

  final bool hasStarted;
  final bool isLoading;
  final DemoUserState? userState;
  final Object? error;
}

class UserStoreDemoCubit extends Cubit<UserStoreDemoState> {
  UserStoreDemoCubit({required UserStoreImpl userStore})
    : _userStore = userStore,
      super(const UserStoreDemoState());

  final UserStoreImpl _userStore;

  Future<void> start() async {
    emit(const UserStoreDemoState(hasStarted: true, isLoading: true));
    try {
      final userState = await _userStore.get();
      emit(UserStoreDemoState(hasStarted: true, userState: userState));
    } catch (error) {
      emit(UserStoreDemoState(hasStarted: true, error: error));
    }
  }
}
