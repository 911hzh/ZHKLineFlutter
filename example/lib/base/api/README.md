# api 目录说明

`api` 用于放置当前 example 工程的网络 API 示例代码，主要展示 `flutter_foundation_kit` 中 `RestClient`、`RestClientAdapter`、`NetworkProxy` 等网络能力的接入方式。

## 当前内容

- `ApiClient.dart`：聚合示例 API，并提供 demo 环境的 `RestClientAdapter`、`NetworkProxy` 实现。
- `UserApi.dart`：演示如何通过 `RestClient` 发起请求并转换模型，同时包含 demo 登录返回结构。
- `model/`：网络返回模型目录，例如 `User.dart`。

## 和 port 的区别

`api` 当前是网络 API 示例封装，不是第三方 SDK 的 Port 抽象层。第三方 SDK 接入时，应优先在 `lib/base/port` 定义接口抽象，再在 `lib/infra` 中提供具体实现。
