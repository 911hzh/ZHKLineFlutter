import 'package:example/base/api/UserApi.dart';
import 'package:example/base/api/KlineApi.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppApiClient {
  AppApiClient({required this.userApi, required this.klineApi});

  final UserApi userApi;
  final KlineApi klineApi;
}
