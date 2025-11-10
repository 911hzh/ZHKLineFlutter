import 'package:flutter/material.dart';
import 'dart:io';

import 'package:k_line_flutter/kline/widgets/ChartPage.dart';

void main() {
  // 配置HTTP代理（如果需要）
  _setupProxy();

  runApp(const MyApp());
}

/// 配置网络代理
void _setupProxy() {
  // 设置HTTP代理地址和端口
  // 示例：本地代理 127.0.0.1:7890（根据实际情况修改）
  const String proxyHost = '127.0.0.1';
  const int proxyPort = 7897;
  const bool enableProxy = false; // 设置为 true 启用代理

  if (enableProxy) {
    final proxyAddress = '$proxyHost:$proxyPort';

    // 配置全局HTTP客户端代理
    HttpOverrides.global = _ProxyHttpOverrides(proxyAddress);

    print('✅ 代理已启用: $proxyAddress');
  } else {
    print('ℹ️ 代理已禁用');
  }
}

/// 自定义 HttpOverrides 实现代理
class _ProxyHttpOverrides extends HttpOverrides {
  final String proxyAddress;

  _ProxyHttpOverrides(this.proxyAddress);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return 'PROXY $proxyAddress';
      }
      // 忽略证书验证（仅用于开发环境，生产环境请谨慎使用）
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter K线图',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const ChartPage(),
    );
  }
}
