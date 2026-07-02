# Changelog

## 0.3.1

- 更新文档

## 0.3.0

- 破坏性调整：移除默认指标 enum API，改为基于 `KLineIndicatorSpec<T>` 和 `KLineIndicatorSeries<T>` 的动态指标定义。
- 新增 `KLineWidget.mainIndicators` / `secondaryIndicators`，指标选择器以传入列表为唯一来源；不传使用默认指标，传空列表表示不展示对应指标。
- 将 `KLineDataAdapter.indicatorValue` 改为接收 `String valueId`，业务侧可以直接支持任意自定义指标值。
- 新增 `KLineDefaultIndicators` class 常量和工厂，保留 MA、EMA、BOLL、VOL、MACD、KDJ、RSI、WR 默认指标能力。
- 支持自定义副图指标：普通 series 指标自动绘制折线、计算范围和展示标签；复杂指标可通过 `KLineIndicatorSpec.renderer` 自定义绘制。
- 优化默认占位高度和视口高度计算，统一通过 delegate 获取高度，避免默认副图和自定义 indicator 高度不一致。
- 修复缩小后旧滚动偏移超过新内容宽度时右侧偶发空白/闪动的问题，并抽离 `ScaleGestureHandler` 管理缩放手势逻辑。
- 更新 example 自定义指标页面，演示默认 VOL、CCI 折线指标和自定义柱状 renderer 混合使用。

## 0.2.0

- 新增 `KLineController` 实时场景控制能力：支持跟随最新、滚动到最新、滚动到指定下标和 reveal 当前选中项。
- 新增实时更新示例页，演示业务层先更新数据，再主动调用 controller 滚动到目标位置。
- 优化 K 线滚动边界同步，修复滚动到底部附近偶发不触发加载更多，以及加载更多后视图偏移漂移的问题。
- 修复 example K 线缓存窗口逻辑，避免刷新 50 条数据时被已加载更多的内存数据污染。
- 调整实时更新 demo 的 timer 行为，只有开启“跟随最新数据”时才自动模拟推送。
- 修复默认指标切换栏高度使用硬编码的问题，改为读取布局配置。
- 补充实时数据接入文档，明确 package 不负责判断数据插入位置。
- 更新发布忽略规则，避免 `build/` 构建产物进入 pub 包。

## 0.1.2

- 将项目 `.fvmrc` 调整为当前 FVM 兼容的 JSON 格式，修复 `fvm flutter` 和 `example` 下 `make gen` 无法执行的问题。
- 同步 `example/pubspec.lock` 中的本地 path 依赖版本到 `0.1.1`。

## 0.1.1

- 更新 package 名称为 `kline_flutter`，同步公共入口和示例导入路径。
- 完善发布配置，补充 `LICENSE`、`.pubignore` 和发布校验所需文件。
- 优化 `README.md` 首屏展示、快速接入说明和核心优势文案。
- 将 README 展示图片切换为 GitHub raw URL，避免图片资源进入 pub 发布包。
- 缩小自定义 UI 图片在 README 中的展示尺寸，提升文档阅读体验。

## 0.1.0

- 初始发布 Flutter K 线图组件。
- 支持 `KLineWidget` 快速接入和 `KLineChartDelegate` 深度自定义绘制。
- 支持 MA、EMA、BOLL、MACD、KDJ、RSI、WR、VOL 等默认指标展示。
- 新增深度图 `DeepChart`，支持买卖盘累计深度展示。
- 提供 example、详细使用文档和自定义 UI 示例。
