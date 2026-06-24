# Flutter Foundation Kit Example Template

这是一个基于轻量级 Port/Infra + GetIt + Module 分层的 Flutter 模板项目。它既可以作为仓库内的示例工程阅读，也可以通过根目录的 `make create <ProjectName>` 生成独立 Flutter app。目标是让开发者或 AI Agent 快速知道页面、接口抽象、第三方 SDK 实现、依赖注册、路由和公共 UI 应该放在哪里。

## 生成新项目

在仓库根目录执行：

```bash
make create helloworldProject
```

需要自定义 app id 或输出父目录时：

```bash
make create helloworldProject BUNDLE_ID=com.company.helloworld OUTPUT=../apps
```

模板已集成能力和生成项目后的开发说明见：[`../QUICK_PROJECT_README.md`](../QUICK_PROJECT_README.md)。

## 快速入口

- 初学者快速上手：`lib/quick_use.md`
- 架构说明和取舍：`lib/ARCHITECTURE_TRADEOFFS.md`
- AI 开发规则：`AI_DEV.md`
- 功能记录：`FEATURE_LOG.md`
- `lib` 目录总览：`lib/README.md`
- K 线示例：`lib/module/usecase/pages/kline/KLineDemoPage.dart`
- 深度图示例：`lib/module/usecase/pages/deep_chart/DeepChartDemoPage.dart`

## 核心目录

- `lib/module/usecase`：页面、Cubit、VM、模块内 Widget。
- `lib/module/getIt`：依赖注入和对象注册。
- `lib/module/route`：路由表和全局导航能力。
- `lib/base/port`：第三方 SDK 或平台能力的接口抽象。
- `lib/infra`：`base/port` 中接口的具体实现。
- `lib/e_uikit`：多个模块共享的 UI 组件。
- `lib/base/api`：示例网络 API 封装。
- `lib/base/store`：共享状态、本地持久化和 Store 示例。

## 行情示例

- K 线图使用火币 `/market/history/kline`，通过 `KlineStore` 缓存并转换为 package 的 adapter 数据。
- 深度图使用火币 `/market/depth` REST 快照，参数为 `symbol=btcusdt`、`depth=20`、`type=step0`。响应中的 `tick.bids` / `tick.asks` 是 `[price, size]`，页面通过 `DeepChartDataAdapter` 映射到 package 的 `DeepChart`。
- REST 深度快照适合 demo 和低频刷新；如果需要实时盘口，后续可接入火币 WebSocket `market.$symbol.depth.$type` 或 MBP 主题。

## 最小规则

页面和业务放 `module/usecase`，接口抽象放 `base/port`，具体实现放 `infra`，依赖注册放 `module/getIt`，路由放 `module/route`，公共 UI 放 `e_uikit`。

## 适合的使用方式

如果你是第一次使用该模板，先阅读 `lib/quick_use.md`。如果你准备让 AI Agent 辅助开发，先把 `AI_DEV.md` 作为项目规则上下文提供给 AI。每次新增功能后，将功能入口、涉及目录和验证方式记录到 `FEATURE_LOG.md`。
