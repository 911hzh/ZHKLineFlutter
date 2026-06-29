import 'dart:io';

import 'package:dio/io.dart';
import 'package:example/module/getIt/GetItInstanceName.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  RestClient restClient(
    RestClientAdapter restAdapter,
    NetworkProxy networkProxy,
  ) {
    return RestClientImpl(
      restAdapter: restAdapter,
      networkProxy: networkProxy,
      createHttpClientAdapter: (networkProxy) =>
          _createHttpClientAdapter(networkProxy: networkProxy),
    );
  }

  @Named(RepositoryGetItInstanceName.auth)
  @lazySingleton
  Repository authRepository() {
    return KeyChainImpl();
  }

  @Named(RepositoryGetItInstanceName.userPreference)
  @lazySingleton
  Repository userPreferenceRepository() {
    return PreferenceRepositoryImpl('user_store');
  }
}

// 通常再这里配置代理，还有配置https 证书认证，
IOHttpClientAdapter _createHttpClientAdapter({
  required NetworkProxy networkProxy,
}) {
  return IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            return true;
          };

      var proxy = networkProxy.findProxy();
      if (proxy != null && proxy.isNotEmpty) {
        client.findProxy = (uri) {
          return proxy;
        };
      }
      return client;
    },
  );
}
