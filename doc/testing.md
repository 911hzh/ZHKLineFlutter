# 测试用例说明

本文档说明当前仓库测试用例的组织方式、覆盖重点，以及是否使用 UI 测试和集成测试。

## 测试目录

根 package 和 example 分开测试：

- 根 package 测试放在 `test/`，对应根包 `lib/` 中的可复用图表库代码。
- example 测试放在 `example/test/`，对应 `example/lib/` 中的示例应用代码。

测试文件尽量镜像源码目录。测试哪个源码文件，就在测试目录下放对应的测试文件；不把多个无关源码文件的测试融合到同一个测试文件中。

## 根 package 测试

根 package 只测试图表库自身能力，不引入 example 的业务逻辑。

当前保留的重点包括：

- public export smoke：确认 `lib/kline_flutter.dart` 统一入口能暴露主要公开类型。
- `KLineController`：状态变更、滚动请求、选中状态、指标切换。
- K 线 delegate 和默认 delegate 工具逻辑：可见区、布局节点、range、图表高度、指标激活。
- K 线 Widget：loading、empty、滚动、缩放、选中、外部 controller 切换。
- 深度图 delegate 和 Widget：累计深度、节点定位、网格/轴标签、loading/empty、默认覆盖层。

已删除低价值或重复测试，例如纯字段默认值、简单 adapter 转发、过细的主题对象 copy 测试等。保留目标是覆盖核心回归风险，而不是为了数量而增加测试。

## Example 测试

example 只测试示例应用自身的接入逻辑，不反向验证 package 内部实现。

当前保留的重点包括：

- `KlineApi_test.dart`：只测试 K 线历史接口请求和解析，不测试 depth API。
- `KlineStore_test.dart`：缓存读取、刷新、排序、分页加载。
- `KLineDemoCubit_test.dart`：初始化、周期切换、刷新最新数据、加载更多防重入。
- `DeepChartDemoCubit_test.dart`：深度图示例数据加载。
- `custom_kline_demo_shell_test.dart`：自定义页面 shell 的重试/加载行为。
- `custom_live_update_cubit_test.dart`：实时更新和跟随最新逻辑。
- `Injection_test.dart`：依赖注册是否能解析。
- `App_test.dart`：示例应用首页路由能展示已注册 demo。

## 有没有用到 UI 测试

有，但这里的 UI 测试是 Flutter Widget Test，不是真机 UI 自动化测试。

仓库中使用 `testWidgets` 和 `WidgetTester` 测试部分 Widget 的渲染和交互，例如：

- `test/src/kline/widgets/kline_chart_test.dart`
- `test/src/kline/widgets/kline_widget_test.dart`
- `test/src/kline/widgets/kline_views_test.dart`
- `test/src/deepchart/widgets/deep_chart_test.dart`
- `example/test/app/App_test.dart`
- `example/test/module/usecase/pages/custom_page/custom_kline_demo_shell_test.dart`

这些测试会 pump Widget，验证 loading、empty、overlay、indicator selector 点击、页面入口等组件级行为。

当前没有使用 golden test，也没有做截图对比类 UI 测试。

## 有没有用到集成测试

没有使用 Flutter `integration_test`。

当前仓库没有 `integration_test/` 目录，也没有 `integration_test`、`flutter_driver`、`patrol` 等端到端测试依赖。`example/test/` 中的测试仍然是普通单元测试或 Widget Test，会通过 fake/mock 数据验证模块协作，但不启动真机、模拟器或浏览器跑完整用户流程。

如果后续要补集成测试，建议只覆盖少量高价值路径，例如：

- example 启动后进入 K 线 demo 页面。
- K 线页面能完成加载、切换周期、下拉/按钮刷新。
- 自定义实时更新页面能开启/关闭跟随最新。

## 常用验证命令

根 package：

```bash
make format-check
make analyze
make test
```

example：

```bash
cd example
flutter analyze
flutter test
```
