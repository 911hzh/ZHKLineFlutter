# infra 目录说明

`infra` 是基础设施实现层，用于放置 `lib/base/port` 中接口的具体实现。这里可以依赖第三方 SDK、平台通道、系统服务或远端服务，但对上层模块暴露时应通过 Port 接口完成。

## 适合放置的内容

- Analytics Port 的具体 SDK 实现。
- Feedback Port 的具体 SDK 或服务端实现。
- Pay Port 的具体支付渠道实现。
- 平台能力、插件能力、第三方服务的适配代码。

## 使用约定

实现类应通过 `module/getIt` 注册为对应 Port 接口，模块层只注入和使用接口。这样可以降低第三方 SDK 替换成本，也方便在测试或 demo 场景中切换实现。
