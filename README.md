# ZHKLine Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.7.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

一个面向金融行情场景的 Flutter 图表库，提供 K 线图、技术指标、交互控制和深度图能力。它以 `CustomPainter` 和 delegate 架构为核心，让你既可以快速接入一套默认 UI，也可以在真实业务中按需替换绘制、布局、覆盖层和数据适配。

详细使用方式、自定义 UI、深度图接入和 example 说明请参考 [`example/use_docs.md`](example/use_docs.md)。

## 效果预览

### 动态指标与指标文案

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_indicator_text.png"
  alt="动态指标与指标文案演示"
  width="360"
/>

[查看动态指标绘制视频](https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_dynamic_indicator_draw.webm)

### 滚动与缩放

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_scrolling.gif"
  alt="滚动与缩放演示"
  width="360"
/>

### 长按详情

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_tap_longpress_dataDetail.gif"
  alt="长按十字线演示"
  width="360"
/>

### 自定义背景

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_background.png"
  alt="自定义背景演示"
  width="360"
/>

### 自定义覆盖层

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_overlay_ui.png"
  alt="自定义覆盖层演示"
  width="360"
/>

### 自定义详情面板

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_detail_ui.png"
  alt="自定义详情面板演示"
  width="360"
/>

### 自定义主图绘制

<img
  src="https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_main_draw.png"
  alt="自定义主图绘制演示"
  width="360"
/>

### 实时数据插入

[查看实时数据插入视频](https://raw.githubusercontent.com/911hzh/ZHKLineFlutter/develop-0.3.0/lib/assets/show/flutter_custom_real_time_data_insert_append_end.webm)

## 为什么选择它

- **几分钟完成接入**：业务页面只需要准备 `List<T>` 和 `KLineDataAdapter<T>`，默认 UI 已包含蜡烛图、指标、副图、长按详情和基础状态展示，不需要为了图表改造已有数据模型。
- **扩展点清晰可控**：通过 `KLineChartDelegate<T>` / `DeepChartDelegate<T>` 暴露绘制流程。想改背景、网格、指标文案、主图绘制、选中浮层或深度图，只替换对应模块即可。
- **指标定义可扩展**：通过 `KLineIndicatorSpec<T>` / `KLineIndicatorSeries<T>` 定义主图和副图指标，不需要改 enum 或 switch；普通折线指标自动绘制，特殊指标可传入 renderer 自定义绘制。
- **默认能力可复用**：自定义 delegate 可以继承 `KLineDefaultDelegateImpl<T>` 并调用 `super` 保留默认蜡烛、指标、网格、覆盖层和选中详情，只在对应方法里追加业务真正关心的那一层 UI。
- **为高频行情优化**：K 线、指标和副图使用 `CustomPainter` 直接绘制，减少大量蜡烛和指标点带来的 Widget rebuild 压力；固定网格层和横向滚动内容层拆开绘制，网格、坐标轴和覆盖层不会跟着内容重复滚动。
- **滑动更贴近原生手感**：横向内容层基于 `SingleChildScrollView`、`ScrollController` 和 Flutter 滚动物理实现，手指松开后的惯性滚动由框架接管；业务分页回调只响应用户主动拖动，避免 `jumpTo` / `animateTo` 这类程序化滚动重复触发加载逻辑。
- **按 120fps 交互目标设计**：滚动、缩放、长按等高频交互会提前计算可见区节点和绘制坐标，减少 paint 阶段重复计算；默认实现交互顺滑、响应稳定，适合承载行情页里连续滑动、缩放和长按查看这类高频操作。
- **业务模型零侵入**：K 线和深度图都通过 adapter 读取字段，后端模型、缓存模型、计算后的指标模型都可以直接接入。
- **架构长期可维护**：核心图表、默认实现、主题布局、controller、example 数据层边界清晰，后续新增指标、替换 UI、接入不同交易所数据时不会牵一发动全身。
- **金融图表能力完整**：内置 MA、EMA、BOLL、MACD、KDJ、RSI、WR、VOL 等常见指标，支持外部控制缩放、滚动、选中状态，也提供盘口累计深度图 `DeepChart`。

## 快速开始

在你的 Flutter 项目中添加依赖：

```bash
flutter pub add kline_flutter
```

或者手动写入 `pubspec.yaml`：

```yaml
dependencies:
  kline_flutter: ^0.3.0
```

然后在业务代码中导入：

```dart
import 'package:kline_flutter/kline_flutter.dart';
```

如果想运行本仓库的示例工程：

```bash
git clone https://github.com/911hzh/ZHKLineFlutter.git
cd ZHKLineFlutter
cd example
flutter pub get
flutter run -d macos
```

## 最小接入

接入时通常只需要准备两部分：

- `MyCandle`：你的业务 K 线数据类，可以来自接口、数据库或本地计算结果。
- `MyCandleAdapter`：把业务数据转换成图表 UI 能识别的 open、high、low、close、volume 和时间文案。

```dart
import 'package:kline_flutter/kline_flutter.dart';

class MyCandle {
  const MyCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timeLabel,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String timeLabel;
}

class MyCandleAdapter extends KLineDataAdapter<MyCandle> {
  const MyCandleAdapter();

  @override
  double open(MyCandle item) => item.open;

  @override
  double high(MyCandle item) => item.high;

  @override
  double low(MyCandle item) => item.low;

  @override
  double close(MyCandle item) => item.close;

  @override
  double volume(MyCandle item) => item.volume;

  @override
  String dateLabel(MyCandle item) => item.timeLabel;
}
```

UI 层在你的某个页面里，直接把数据数组和 adapter 传给 `KLineWidget` 即可：

```dart
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return KLineWidget<MyCandle>(
      dataSource: candles,
      adapter: const MyCandleAdapter(),
      initialIndicators: const [KLineDefaultIndicators.volumeId],
    );
  }
}
```

## 更多用法

README 只保留最小接入。动态指标、实时数据、外部控制、自定义绘制、自定义 UI、
Loading / Empty / Error 和深度图接入，请查看 [`example/use_docs.md`](example/use_docs.md)。

## 核心能力

### K 线图

- `KLineWidget<T>`：默认 K 线 UI，适合快速接入。
- `KLineChart<T>`：核心图表组件，适合完全自定义绘制。
- `KLineChartDelegate<T>`：绘制协议，可控制布局节点、网格、主图、副图、覆盖层和选中 UI。
- `KLineDataAdapter<T>`：业务模型适配器。
- `KLineController`：缩放、滚动、选中、可见区和指标状态控制。
- `KLineIndicatorSpec<T>`：动态指标定义，可用于主图、副图和自定义 renderer。

### 深度图

- `DeepChart<T>`：默认深度图组件。
- `DeepChartDataAdapter<T>`：盘口数据适配器。
- `DeepChartDelegate<T>`：深度图绘制协议。
- `DeepChartLayoutConfig`：中间图形区域和底部价格行的布局配置。

## 简洁项目结构

```text
lib/
├── kline_flutter.dart
└── src/
    ├── kline/
    └── deepchart/

example/
├── lib/base/api/
├── lib/base/store/
└── lib/module/usecase/pages/
    ├── kline/
    ├── deep_chart/
    └── custom_page/
```

## 架构一览

架构图单独放在文档页，方便通过网页方式查看：

[查看完整架构图](docs/architecture.md)

## 适合场景

- 交易所行情页、合约行情页、股票/基金行情页。
- 需要快速接入默认 K 线 UI 的业务。
- 需要深度定制金融图表绘制协议的业务。
- 需要统一维护 K 线、技术指标、盘口深度和图表交互的 Flutter 项目。

## 参与维护

这个库还在持续完善中，欢迎大家一起参与维护：

- 提交 Issue 反馈 Bug、性能问题或 API 设计建议。
- 提交 Pull Request 补充图表能力、example、测试和文档。
- 分享真实业务中的自定义 delegate、主题和交互方案。

如果这个项目对你有帮助，欢迎点一个 Star，也欢迎一起把它维护成更好用的 Flutter 金融图表库。

## License

本项目采用 MIT License，详情见 [LICENSE](LICENSE)。
