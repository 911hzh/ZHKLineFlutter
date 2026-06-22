import 'package:example/base/api/AppApiClient.dart';
import 'package:example/base/api/model/User.dart';
import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:example/module/getIt/GetItInstanceName.dart';
import 'package:flutter_foundation_kit/cutil/Lazyload.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_foundation_kit/wcore/store/UserStore.dart';
import 'package:injectable/injectable.dart';

const _userCachePrefix = 'user.profile';

class DemoUserState extends UserState {
  final User user;
  DemoUserState({required super.userId, required this.user});

  factory DemoUserState.empty() {
    return DemoUserState(
      userId: '',
      user: User(id: 0, userId: '', title: '', completed: false),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'userId': userId, 'user': user.toJson()};
  }

  factory DemoUserState.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return DemoUserState(
      userId: json['userId'] as String? ?? '',
      user: userJson is Map<String, dynamic>
          ? User.fromJson(userJson)
          : DemoUserState.empty().user,
    );
  }
}

@lazySingleton
class UserStoreImpl extends UserStore<DemoUserState> {
  final AppApiClient apiClient;
  final AuthStoreImpl authStore;
  final Repository _preferenceRepositoryPort;
  late final Lazyload<DemoUserState> userLazyload;
  UserStoreImpl({
    required this.apiClient,
    required this.authStore,
    @Named(RepositoryGetItInstanceName.userPreference)
    required Repository preferenceRepositoryPort,
  }) : _preferenceRepositoryPort = preferenceRepositoryPort,
       super(initialState: DemoUserState.empty()) {
    userLazyload = Lazyload<DemoUserState>(() async {
      final authState = await authStore.get();
      if (authState.userId.isEmpty) {
        final emptyState = DemoUserState.empty();
        setState(emptyState);
        return emptyState;
      }
      final cachedJson = await _preferenceRepositoryPort
          .getValue<String, Map<String, dynamic>>(await _cacheKey());
      if (cachedJson != null) {
        final cachedState = DemoUserState.fromJson(cachedJson);
        setState(cachedState);
      }

      final response = await apiClient.userApi.fetchTodo();
      final userState = DemoUserState(
        userId: authState.userId,
        user: response.data,
      );
      await _preferenceRepositoryPort.setValue<String, Map<String, dynamic>>(
        await _cacheKey(),
        userState.toJson(),
      );
      setState(userState);
      return userState;
    });
  }

  @override
  Future<DemoUserState> get() async {
    return await userLazyload.get();
  }

  @override
  void dirty() {
    userLazyload.dirty();
    setState(DemoUserState.empty());
  }

  @override
  void renew() {
    get();
  }

  Future<String> _cacheKey() async {
    final authState = await authStore.get();
    return '$_userCachePrefix.${authState.userId}';
  }
}
