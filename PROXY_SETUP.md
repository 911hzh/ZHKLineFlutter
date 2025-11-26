# 代理设置说明

## 📡 功能说明

在 `lib/main.dart` 中添加了 HTTP 代理配置功能，用于：

- 通过代理访问外部 API（如火币 API）
- 解决网络访问限制问题
- 调试网络请求

## 🚀 如何使用

### 1. 启用代理

打开 `lib/main.dart`，找到 `_setupProxy()` 函数：

```dart
void _setupProxy() {
  // 设置HTTP代理地址和端口
  const String proxyHost = '127.0.0.1';  // 修改为你的代理地址
  const int proxyPort = 7890;             // 修改为你的代理端口
  const bool enableProxy = true;          // 改为 true 启用代理

  // ...
}
```

### 2. 配置参数

根据你的代理软件修改参数：

| 代理软件     | 默认地址  | 默认端口 |
| ------------ | --------- | -------- |
| Clash        | 127.0.0.1 | 7890     |
| V2rayU       | 127.0.0.1 | 1087     |
| ShadowsocksX | 127.0.0.1 | 1080     |
| Charles      | 127.0.0.1 | 8888     |
| Fiddler      | 127.0.0.1 | 8888     |

### 3. 常见配置示例

#### Clash 代理

```dart
const String proxyHost = '127.0.0.1';
const int proxyPort = 7890;
const bool enableProxy = true;
```

#### V2rayU 代理

```dart
const String proxyHost = '127.0.0.1';
const int proxyPort = 1087;
const bool enableProxy = true;
```

#### 远程代理服务器

```dart
const String proxyHost = '192.168.1.100';  // 远程服务器IP
const int proxyPort = 8080;
const bool enableProxy = true;
```

## 📝 实现原理

### 1. HttpOverrides

使用 Dart 的 `HttpOverrides` 类来配置全局 HTTP 代理：

```dart
class _ProxyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) => 'PROXY $proxyAddress';
  }
}
```

### 2. 全局配置

在应用启动时设置全局代理：

```dart
void main() {
  _setupProxy();  // 配置代理
  runApp(const MyApp());
}
```

### 3. 证书验证

开发环境下忽略 SSL 证书验证（**生产环境请删除此选项**）：

```dart
..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
```

## ⚠️ 注意事项

### 1. 安全性

- ✅ 开发环境：可以禁用证书验证方便调试
- ❌ 生产环境：**必须**启用证书验证，删除 `badCertificateCallback`

生产环境配置：

```dart
@override
HttpClient createHttpClient(SecurityContext? context) {
  return super.createHttpClient(context)
    ..findProxy = (uri) => 'PROXY $proxyAddress';
  // 移除 badCertificateCallback
}
```

### 2. 性能影响

- 启用代理可能会影响网络请求速度
- 建议只在需要时启用
- 发布版本建议禁用代理

### 3. 平台兼容性

- ✅ macOS - 完全支持
- ✅ Windows - 完全支持
- ✅ Linux - 完全支持
- ✅ Android - 完全支持
- ✅ iOS - 完全支持
- ✅ Web - 浏览器自动处理代理

## 🔍 调试

### 查看代理状态

应用启动时会在控制台输出：

```
✅ 代理已启用: 127.0.0.1:7890
```

或

```
ℹ️ 代理已禁用
```

### 测试代理是否工作

1. **启用代理**

   ```dart
   const bool enableProxy = true;
   ```

2. **运行应用**

   ```bash
   flutter run
   ```

3. **查看网络请求**
   - 如果能成功获取 K 线数据，说明代理工作正常
   - 如果请求失败，检查代理地址和端口是否正确

### 常见问题

#### 1. 代理连接失败

```
Error: SocketException: Connection refused
```

**解决方案**：

- 检查代理软件是否运行
- 确认代理地址和端口正确
- 检查防火墙设置

#### 2. HTTPS 证书错误

```
Error: HandshakeException: Handshake error
```

**解决方案**：

- 确保 `badCertificateCallback` 已配置（开发环境）
- 或安装代理软件的根证书（生产环境）

#### 3. 代理不生效

**解决方案**：

- 确认 `enableProxy = true`
- 重新启动应用
- 检查代理软件的系统代理设置

## 🎯 最佳实践

### 1. 环境变量配置

使用环境变量管理代理配置：

```dart
void _setupProxy() {
  // 从环境变量读取配置
  final proxyHost = const String.fromEnvironment('PROXY_HOST', defaultValue: '127.0.0.1');
  final proxyPort = const int.fromEnvironment('PROXY_PORT', defaultValue: 7890);
  final enableProxy = const bool.fromEnvironment('ENABLE_PROXY', defaultValue: false);

  // ...
}
```

运行时指定：

```bash
flutter run --dart-define=ENABLE_PROXY=true --dart-define=PROXY_HOST=127.0.0.1 --dart-define=PROXY_PORT=7890
```

### 2. 条件编译

只在 debug 模式启用代理：

```dart
void _setupProxy() {
  const bool enableProxy = false;

  // 只在 debug 模式下启用
  assert(() {
    enableProxy = true;  // Debug 模式自动启用
    return true;
  }());

  // ...
}
```

### 3. 配置文件

创建 `config/proxy_config.dart`：

```dart
class ProxyConfig {
  static const String host = '127.0.0.1';
  static const int port = 7890;
  static const bool enabled = false;
}
```

## 📚 相关文档

- [Dart HttpOverrides 文档](https://api.dart.dev/stable/dart-io/HttpOverrides-class.html)
- [Dio 代理配置](https://pub.dev/packages/dio#proxy)
- [Flutter 网络调试](https://flutter.dev/docs/development/data-and-backend/networking)

## ✅ 总结

代理配置已添加到 `main.dart`，使用步骤：

1. 设置 `proxyHost` 和 `proxyPort`
2. 设置 `enableProxy = true`
3. 重新运行应用
4. 查看控制台确认代理状态

记住：**生产环境务必禁用代理或移除证书验证代码！**
