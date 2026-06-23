# module 目录说明

`module` 用于组织业务模块、demo 页面、依赖注册和路由配置。当前 example 工程主要在这里展示 `flutter_foundation_kit` 的使用方式，每个 demo 主题可以包含 Page、Cubit、VM 和局部 Widget。

## 当前内容

- `usecase/pages/home`：demo 首页和入口列表。
- `usecase/pages/login`、`logout`：登录和退出登录示例。
- `usecase/pages/apiImpl`：REST Client 调用示例。
- `usecase/pages/store`、`userStore`、`settings`：Store 和设置能力示例。
- `usecase/pages/logger`、`cutil`：日志和工具能力示例。
- `usecase/pages/custom_page`：K 线高度自定义能力示例，一个扩展点对应一个独立页面。
- `getIt`：依赖注入和对象注册。
- `route`：页面路由表和全局导航能力。

## K 线自定义示例路由

`custom_page` 目录用于说明 package 的扩展性和可维护性。每个页面只聚焦一个自定义点，便于快速定位示例代码。

- `/kline/custom/theme-layout`：自定义主题、布局和交互配置。
- `/kline/custom/indicator-entries`：自定义指标标签、指标顺序和长按详情字段。
- `/kline/custom/overlay`：自定义覆盖层 UI 和指标切换栏。
- `/kline/custom/selection-view`：自定义长按选中详情浮层。
- `/kline/custom/grid`：自定义固定网格、水印和辅助线。
- `/kline/custom/main-chart`：自定义主图绘制内容。
- `/kline/custom/secondary-chart`：自定义副图绘制内容。
- `/kline/custom/controller`：通过 `KLineController` 外部控制缩放、滚动、选中和指标。
- `/kline/custom/state-builders`：自定义 loading、empty、error 和 retry UI。
- `/kline/custom/core-chart`：直接使用 `KLineChart` 和 `KLineChartDelegate` 完全自定义图表。

## 使用约定

模块目录主要负责页面展示、交互入口、状态编排和模块入口组装。需要第三方 SDK 能力时，页面用例应依赖 `base/port` 中的接口，并通过 `module/getIt` 获取实现，避免直接调用 `infra` 或具体 SDK。
