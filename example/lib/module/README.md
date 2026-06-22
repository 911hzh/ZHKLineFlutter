# module 目录说明

`module` 用于组织业务模块、demo 页面、依赖注册和路由配置。当前 example 工程主要在这里展示 `flutter_foundation_kit` 的使用方式，每个 demo 主题可以包含 Page、Cubit、VM 和局部 Widget。

## 当前内容

- `usecase/pages/home`：demo 首页和入口列表。
- `usecase/pages/login`、`logout`：登录和退出登录示例。
- `usecase/pages/apiImpl`：REST Client 调用示例。
- `usecase/pages/store`、`userStore`、`settings`：Store 和设置能力示例。
- `usecase/pages/logger`、`cutil`：日志和工具能力示例。
- `getIt`：依赖注入和对象注册。
- `route`：页面路由表和全局导航能力。

## 使用约定

模块目录主要负责页面展示、交互入口、状态编排和模块入口组装。需要第三方 SDK 能力时，页面用例应依赖 `base/port` 中的接口，并通过 `module/getIt` 获取实现，避免直接调用 `infra` 或具体 SDK。
