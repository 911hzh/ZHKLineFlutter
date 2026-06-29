# Changelog

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
