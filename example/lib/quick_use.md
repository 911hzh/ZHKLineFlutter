# 快速上手

这份文档给第一次使用该模板的开发者阅读。模板可以通过根目录的 `make create <ProjectName>` 生成独立 Flutter app，也可以直接阅读 `example` 工程了解推荐结构。目标是让你快速判断：新页面、新 SDK、新接口、新 Store、新公共组件应该放在哪个目录。

## 先记住一句话

页面和业务放 `module/usecase`，接口抽象放 `base/port`，具体实现放 `infra`，依赖注册放 `module/getIt`，路由放 `module/route`，公共 UI 放 `e_uikit`。

## 目录速查

### 我要新增一个页面

放到 `lib/module/usecase`。

适合放：

- 页面 `Page`
- 页面状态 `Cubit`
- 页面数据模型 `VM`
- 只服务当前页面的小 Widget

示例：

```text
lib/module/usecase/pages/pay/
  PayDemoPage.dart
  PayDemoCubit.dart
```

如果页面需要被打开，还要同步修改 `lib/module/route/RouteConfig.dart`。

### 我要接入第三方 SDK

先在 `lib/base/port` 定义接口，再在 `lib/infra` 写实现。

例如要接入 analytics：

```text
lib/base/port/analytics/
  AnalyticsPort.dart

lib/infra/analytics/
  AnalyticsPortImpl.dart
```

`AnalyticsPort.dart` 只描述业务需要什么能力，例如 `trackEvent`、`setUserId`。不要在这里直接写第三方 SDK 的调用代码。

`AnalyticsPortImpl.dart` 才负责真正调用第三方 SDK。

### 我要注册依赖

放到 `lib/module/getIt`。

适合放：

- Port 和 Infra 的绑定关系
- Store 注册
- 网络客户端注册
- Repository 注册
- 需要命名实例的依赖配置

常见文件：

```text
lib/module/getIt/Injection.dart
lib/module/getIt/RegisterModule.dart
lib/module/getIt/GetItInstanceName.dart
```

模块里需要使用某个能力时，优先通过 `getIt` 获取接口，而不是直接创建实现类。

### 我要新增网络 API

放到 `lib/base/api`。

适合放：

- REST API 封装
- 请求方法
- 网络返回模型
- 示例项目里的后端接口调用

示例：

```text
lib/base/api/OrderApi.dart
lib/base/api/model/Order.dart
```

注意：`base/api` 是网络 API 示例封装，不是第三方 SDK 的接口抽象层。第三方 SDK 抽象应放到 `base/port`。

### 我要新增本地状态或持久化能力

放到 `lib/base/store`。

适合放：

- 登录状态
- 用户信息
- 设置项
- 本地缓存
- 需要多个模块共享的数据读写能力

示例：

```text
lib/base/store/user/UserStoreImpl.dart
lib/base/store/settings/SettingsStore.dart
```

### 我要新增路由

放到 `lib/module/route`。

适合放：

- 页面路径
- 页面构建入口
- 全局导航 key

新增页面后，通常需要在 `lib/module/route/RouteConfig.dart` 添加路由。

### 我要新增公共 UI 组件

放到 `lib/e_uikit`。

适合放：

- 通用按钮
- 通用卡片
- 通用列表项
- 空状态组件
- 加载状态组件
- 多个页面都会复用的 Widget

不要把业务流程、SDK 调用、接口请求放到 `e_uikit`。

## 新功能放置判断

如果你不知道代码应该放哪里，可以按下面顺序判断：

1. 是页面、页面状态或页面交互吗？放 `module/usecase`。
2. 是第三方 SDK 的业务接口吗？放 `base/port`。
3. 是第三方 SDK 的具体实现吗？放 `infra`。
4. 是依赖注入和对象注册吗？放 `module/getIt`。
5. 是页面路径和导航入口吗？放 `module/route`。
6. 是多个页面复用的 UI 吗？放 `e_uikit`。
7. 是网络 API 调用吗？放 `base/api`。
8. 是共享状态或本地持久化吗？放 `base/store`。

## 推荐开发流程

### 新增一个普通页面

1. 在 `lib/module/usecase` 下创建页面目录。
2. 创建 `Page` 和需要的 `Cubit`。
3. 在 `lib/module/route/RouteConfig.dart` 注册路由。
4. 如果首页需要入口，把入口加入首页列表。

### 新增一个第三方 SDK 能力

1. 在 `lib/base/port` 定义接口。
2. 在 `lib/infra` 实现接口。
3. 在 `lib/module/getIt` 注册接口和实现。
4. 在 `lib/module` 中通过接口使用能力。

### 新增一个公共 UI

1. 在 `lib/e_uikit` 创建组件。
2. 保持组件无业务依赖。
3. 在需要的 `module` 页面中复用。

## 一个完整例子

假设要新增支付能力和支付 demo 页面，可以这样放：

```text
lib/base/port/pay/
  PayPort.dart

lib/infra/pay/
  PayPortImpl.dart

lib/module/usecase/pages/pay/
  PayDemoPage.dart
  PayDemoCubit.dart

lib/module/getIt/
  RegisterModule.dart

lib/module/route/
  RouteConfig.dart
```

依赖方向是：

```text
PayDemoPage / PayDemoCubit
  -> PayPort
  -> PayPortImpl
  -> 第三方支付 SDK
```

页面只知道 `PayPort`，不直接依赖第三方支付 SDK。这样后续更换支付 SDK、增加 mock 实现或做单元测试都会更简单。

## 初学者最容易放错的地方

- 不要把第三方 SDK 调用直接写进 `Page`。
- 不要把第三方 SDK 的具体实现写进 `base/port`。
- 不要把业务逻辑写进 `e_uikit`。
- 不要新增页面后忘记注册路由。
- 不要在模块里到处手动 `new` 依赖对象，优先通过 `getIt` 管理。

## 最小心智模型

你可以把这个模板理解成：

```text
module/usecase 负责使用能力
base/port 负责定义能力
infra 负责实现能力
module/getIt 负责组装能力
module/route 负责打开页面
e_uikit 负责复用 UI
```

只要遵守这个方向，项目变大后目录仍然会比较清晰。
