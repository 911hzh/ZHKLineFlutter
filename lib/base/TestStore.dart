import 'package:injectable/injectable.dart';
import 'package:k_line_flutter/base/api/ApiClient.dart';

@Singleton()
class TestStore {
  final ApiClient apiClient;
  final String name = 'TestStore';
  TestStore(this.apiClient);
}
