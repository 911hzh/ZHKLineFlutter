import 'package:example/base/api/model/LoginResponse.dart';
import 'package:example/base/api/model/User.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class UserApi {
  UserApi({required this.client});

  final RestClient client;

  Future<RestResponse<User>> fetchTodo() async {
    return client.get('/todos/1').toModel(User.fromJson);
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    return LoginResponse(token: 'demo-token-$username', userId: '1');
  }
}
