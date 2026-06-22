import 'package:example/base/api/UserApi.dart';
import 'package:example/base/api/model/User.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiImplState {
  const ApiImplState({
    this.hasStarted = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  final bool hasStarted;
  final bool isLoading;
  final User? user;
  final Object? error;

  ApiImplState copyWith({
    bool? hasStarted,
    bool? isLoading,
    User? user,
    Object? error,
  }) {
    return ApiImplState(
      hasStarted: hasStarted ?? this.hasStarted,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class ApiImplCubit extends Cubit<ApiImplState> {
  ApiImplCubit({required UserApi api})
    : _api = api,
      super(const ApiImplState());

  final UserApi _api;

  Future<void> fetchTodo() async {
    emit(const ApiImplState(hasStarted: true, isLoading: true));
    try {
      final response = await _api.fetchTodo();
      emit(ApiImplState(hasStarted: true, user: response.data));
    } catch (error) {
      emit(ApiImplState(hasStarted: true, error: error));
    }
  }
}
