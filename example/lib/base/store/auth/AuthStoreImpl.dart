import 'package:example/module/getIt/GetItInstanceName.dart';
import 'package:flutter_foundation_kit/cutil/Lazyload.dart';
import 'package:flutter_foundation_kit/wcore/Repository.dart';
import 'package:flutter_foundation_kit/wcore/store/AuthStore.dart';
import 'package:injectable/injectable.dart';

const _authTokenKey = 'auth_token';

class DemoAuthState extends AuthState {
  DemoAuthState({required super.token, required super.userId});

  factory DemoAuthState.empty() {
    return DemoAuthState(token: '', userId: '');
  }

  @override
  Map<String, dynamic> toJson() {
    return {'token': token, 'userId': userId};
  }

  factory DemoAuthState.fromJson(Map<String, dynamic> json) {
    return DemoAuthState(
      token: json['token'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
    );
  }
}

@lazySingleton
class AuthStoreImpl extends AuthStore<DemoAuthState> {
  late final Lazyload<DemoAuthState> authLazyload;
  AuthStoreImpl({
    @Named(RepositoryGetItInstanceName.auth) required Repository keychainPort,
  }) : super(keychainPort: keychainPort, initialState: DemoAuthState.empty()) {
    authLazyload = Lazyload<DemoAuthState>(() async {
      final result = await keychainPort.getValue<String, Map<String, dynamic>>(
        _authTokenKey,
      );
      return DemoAuthState.fromJson(result ?? {});
    });
    authLazyload.get();
  }

  @override
  Future<DemoAuthState> loginWithToken(
    String token, {
    required String userId,
  }) async {
    final authState = DemoAuthState(token: token, userId: userId);
    await keychainPort.setValue<String, Map<String, dynamic>>(
      _authTokenKey,
      authState.toJson(),
    );
    setState(authState);
    return authState;
  }

  @override
  Future<void> logout() async {
    await keychainPort.setValue<String, Map<String, dynamic>>(
      _authTokenKey,
      null,
    );
    setState(DemoAuthState.empty());
  }

  @override
  Future<DemoAuthState> get() async {
    return await authLazyload.get();
  }

  @override
  void dirty() {
    keychainPort.setValue<String, Map<String, dynamic>>(_authTokenKey, null);
    setState(DemoAuthState.empty());
  }

  @override
  void renew() {
    get();
  }
}
