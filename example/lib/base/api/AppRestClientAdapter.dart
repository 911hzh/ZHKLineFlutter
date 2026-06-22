import 'package:example/base/store/settings/SettingsStore.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: RestClientAdapter)
class AppRestClientAdapter extends RestClientAdapter {
  AppRestClientAdapter({required this.settingsStore});

  final SettingsStore settingsStore;

  @override
  String getBaseUrl() {
    return settingsStore.state.baseUrl;
  }

  @override
  Future<Map<String, String>> getHeaders() async {
    return {'X-App-Source': 'flutter_foundation_kit_template'};
  }
}
