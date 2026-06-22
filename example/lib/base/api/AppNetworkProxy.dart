import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: NetworkProxy)
class AppNetworkProxy extends NetworkProxy {
  AppNetworkProxy() : super(proxyIp: "PROXY 192.168.1.77:9090");
}
