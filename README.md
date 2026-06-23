# ZHKLine Flutter 📈

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.7.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

一个高性能、功能完整的 Flutter K 线图表库，专为金融应用设计。本项目是 [ZHKLine Swift 版本](https://github.com/911hzh/ZHKLineFlutter/tree/develop)的 Flutter 跨平台实现，采用先进的绘制架构，支持多种技术指标，提供流畅的用户交互体验。

**参考火币的 UI 设计实现，数据来源于火币 API**

---

## ✨ 特性

### 🚀 高性能绘制

- ⚡️ **CustomPainter 自定义绘制** - 60 FPS 流畅渲染 2000+ K 线数据
- 📊 **分层架构** - 网格线、蜡烛图、指标线、十字线分层管理，避免重复绘制
- 🎯 **智能渲染** - 只绘制可见区域，大幅降低 CPU/GPU 负载
- 💾 **预计算缓存** - 所有技术指标和位置信息预先计算，避免实时运算

### 📈 完整的技术指标

- **主图指标**: MA (5/10/30)、EMA (5/10/30)、BOLL (20, 2)
- **副图指标**: MACD (12/26/9)、KDJ (9/3/3)、RSI (6/12/24)、WR (6/10/14)、VOL (5/10)
- **自动计算**: 所有技术指标由库自动计算，无需手动处理

### 🎮 流畅的手势交互

- 🔍 **双指缩放** - 0.5x-3.0x 缩放蜡烛宽度
- 📱 **平滑滚动** - 单指拖动浏览历史数据
- ➕ **长按十字线** - 查看特定 K 线详细信息
- 🎨 **专业 UI** - 参考火币设计，涨红跌绿配色方案

### 🌍 跨平台支持

完全匹配 Swift 版本实现，一套代码支持 iOS、Android、Web、Desktop

---

## 📸 效果展示

### 📊 技术指标切换

展示如何在主图和副图之间切换不同的技术指标（MA、BOLL、MACD、KDJ 等），所有指标数据实时渲染，流畅无卡顿。

![技术指标切换演示](lib/assets/show/flutter_indicator.gif)

### 🔄 流畅滚动与缩放

展示单指拖动浏览历史数据和双指缩放功能，支持 0.5x-3.0x 缩放范围，60 FPS 流畅渲染 2000+ K 线数据。

![滚动与缩放演示](lib/assets/show/flutter_scrolling.gif)

### 📍 长按十字线详情

展示长按图表时显示十字线和数据详情面板，包括当前 K 线的 OHLCV 数据和所有技术指标数值，精准对齐。

![长按十字线演示](lib/assets/show/flutter_tap_longpress_dataDetail.gif)

---

## 🚀 快速开始

### 安装

```bash
# 克隆项目
git clone https://github.com/911hzh/ZHKLineFlutter.git
cd k_line_flutter

# 安装依赖
flutter pub get

# 运行项目
flutter run -d macos  # 或 ios / android
```

### Package 基础用法

新的 package API 推荐只导入一个公共入口。核心思想是：package 内部只负责滚动、手势、视口状态和回调调度；数据直接传入数组，网格、蜡烛、指标、覆盖层和选中 UI 都由外部 delegate 实现。

```dart
import 'package:k_line_flutter/k_line_flutter.dart';

class MyCandle {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime time;

  MyCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.time,
  });
}

class MyDelegate extends KLineChartDelegate<MyCandle> {
  const MyDelegate();

  @override
  List<KLineLayoutNode<MyCandle>> getLayoutNodes(
    KLineChartContext<MyCandle> context,
    List<MyCandle> dataSource,
  ) {
    // 可以复用默认工具，也可以返回业务自己的 KLineLayoutNode 子类。
    return super.getLayoutNodes(context, dataSource);
  }

  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<MyCandle> context) {
    // 外部决定网格如何绘制。
  }

  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<MyCandle> context,
  ) {
    // 外部决定主图蜡烛、折线、MA/BOLL 等如何绘制。
  }

  @override
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<MyCandle> context,
  ) {
    // 外部决定 VOL、MACD、KDJ 等副图如何绘制。
  }

  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<MyCandle> chartContext,
    KLineLayoutNode<MyCandle> selectedNode,
  ) {
    return Text('Close: ${selectedNode.item.close}');
  }

  @override
  void didSelectItem(
    KLineChartContext<MyCandle> context,
    KLineLayoutNode<MyCandle> node,
  ) {
    // 外部处理长按/点击选中。
  }

  @override
  void didMoveSelection(
    KLineChartContext<MyCandle> context,
    KLineLayoutNode<MyCandle> node,
  ) {
    // 外部处理长按后移动到另一个数据点。
  }

  @override
  void didScroll(KLineChartContext<MyCandle> context, KLineScrollMetrics metrics) {
    // 根据 metrics.extentBefore / extentAfter 判断是否加载更多数据。
  }
}

KLineChart<MyCandle>(
  dataSource: candles,
  delegate: const MyDelegate(),
  controller: KLineController(),
  theme: const KLineTheme(),
)
```

这套 API 的核心是：

- `dataSource: List<T>`：外部直接提供需要绘制的数据数组。
- `KLineChartDelegate<T>`：外部决定图表高度、布局节点、网格层、主图、副图、选中 UI 和交互回调。
- `KLineChartContext<T>`：package 在每次绘制和交互时传入的上下文，包含 controller、可见区、布局节点、视口尺寸、主题和布局配置。
- `KLineController`：对外暴露缩放、滚动、选中项、可见区间等状态。

### 自定义绘制示例

```dart
class OrderLineDelegate extends KLineChartDelegate<MyCandle> {
  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<MyCandle> context) {
    super.drawGrid(canvas, size, context);
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }
}
```

### 自定义配置

```dart
KLineChart<MyCandle>(
  dataSource: candles,
  delegate: const MyDelegate(),
  theme: const KLineTheme(
    candleUpColor: Color(0xFFF14965),
    candleDownColor: Color(0xFF00B066),
  ),
  layout: const KLineLayoutConfig(
    candleWidth: 8,
    candleSpacing: 2,
    mainChartHeight: 360,
  ),
  behavior: const KLineBehaviorConfig(
    enableScale: true,
    enableCrosshair: true,
  ),
)
```

---

## 📖 核心组件

### KLineChart

package 核心组件，只负责滚动、手势、视口上下文和代理调度，不包含具体 K 线业务绘制。

```dart
KLineChart<T>(
  dataSource: List<T>,                 // 数据数组
  delegate: KLineChartDelegate<T>,     // 绘制和交互代理
  controller: KLineController?,        // 状态控制器
  theme: KLineTheme,                   // 主题配置
  layout: KLineLayoutConfig,           // 布局配置
  behavior: KLineBehaviorConfig,       // 交互配置
)
```

### KLineChartDelegate

绘制和交互协议，外部负责网格、蜡烛、指标、覆盖层、选中 UI 和交互回调。

```dart
abstract class KLineChartDelegate<T> {
  double chartHeight(KLineChartContext<T> context);
  List<KLineLayoutNode<T>> getLayoutNodes(
    KLineChartContext<T> context,
    List<T> dataSource,
  );
  void drawChart(Canvas canvas, Size size, KLineChartContext<T> context);
  void drawGrid(Canvas canvas, Size size, KLineChartContext<T> context);
  void drawMainChart(Canvas canvas, Size size, KLineChartContext<T> context);
  void drawSecondaryCharts(Canvas canvas, Size size, KLineChartContext<T> context);
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<T> chartContext,
    KLineLayoutNode<T> selectedNode,
  );
  Widget? buildOverlayView(BuildContext context, KLineChartContext<T> chartContext);
  void didScroll(KLineChartContext<T> context, KLineScrollMetrics metrics);
  void didSelectItem(KLineChartContext<T> context, KLineLayoutNode<T> node);
  void didMoveSelection(KLineChartContext<T> context, KLineLayoutNode<T> node);
}
```

---

## 🏗 架构设计

### 核心设计原则

1. **职责分离** - 数据计算、位置计算、视图渲染完全分离
2. **预计算优化** - 所有位置信息预先计算，避免重复计算
3. **分层绘制** - 网格、蜡烛、指标、十字线分层管理

### 绘制流程

```
原始数据 → 技术指标计算 → 坐标位置计算 → CustomPainter 绘制 → 手势交互
    ↓            ↓                ↓                  ↓              ↓
KLineData  →  Indicators  →  DrawPoints  →  Canvas.draw  →  GestureDetector
```

### 关键组件

| 组件                     | 职责                                   |
| ------------------------ | -------------------------------------- |
| **KLineChart**           | 滚动、手势、视口上下文和代理调度       |
| **List<T> dataSource**   | 当前图表需要绘制的数据数组             |
| **KLineChartDelegate**   | 布局节点、网格、主图、副图、选中 UI 绘制 |
| **KLineChartContext**    | 每次绘制和交互时传给外部的上下文       |
| **KLineController**      | 缩放、滚动、选中项、可见区间状态       |

---

## 📊 技术指标

核心 package 不内置 MA、EMA、BOLL、MACD 等业务指标计算和绘制。外部可以在 `KLineChartDelegate.getLayoutNodes` / `drawMainChart` / `drawSecondaryCharts` 中自行计算并绘制，也可以在业务层预先计算好指标数据后放入 `dataSource` 数组。

---

## 📁 项目结构

```
lib/
├── k_line_flutter.dart              # package 公共入口
└── src/kline/
    ├── controller/                  # KLineController
    ├── delegate/                    # Delegate / Context
    ├── theme/                       # Theme / Layout / Behavior 配置
    └── widgets/                     # KLineChart 核心组件

example/
└── main.dart                        # 如何传入数据并实现 delegate 完成具体绘制
```

---

## 🎯 与 Swift 版本对应

| 功能       | Swift              | Flutter               |
| ---------- | ------------------ | --------------------- |
| **绘制层** | CALayer            | CustomPainter         |
| **视图层** | UIView             | StatefulWidget        |
| **滚动**   | UIScrollView       | SingleChildScrollView |
| **缩放**   | UIPinchGesture     | onScaleUpdate         |
| **长按**   | UILongPressGesture | onLongPress           |
| **配置**   | 配置对象           | KLineTheme/Layout     |
| **数据**   | DataSource         | List<T> dataSource    |
| **代理**   | Delegate           | KLineChartDelegate    |

---

## 📊 性能数据

| 测试场景   | 数据量  | 帧率   | 内存  |
| ---------- | ------- | ------ | ----- |
| 滚动浏览   | 2000 条 | 60 FPS | ~50MB |
| 双指缩放   | 2000 条 | 60 FPS | ~50MB |
| 长按十字线 | 2000 条 | 60 FPS | ~50MB |
| 切换指标   | 2000 条 | 60 FPS | ~55MB |

---

## 🛠 技术栈

- **Flutter**: 3.7.0+
- **Dart**: 3.7.0+
- **dio**: ^5.9.0 - HTTP 网络请求
- **get_it**: ^8.2.0 - 依赖注入
- **injectable**: ^2.5.1 - 依赖注入代码生成
- **intl**: ^0.19.0 - 日期格式化

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 提交规范

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式
- `refactor`: 重构
- `perf`: 性能优化

---

## 📄 License

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

## 🔗 相关链接

- **Swift 版本**: [ZHKLine iOS](https://github.com/911hzh/ZHKLineFlutter/tree/develop)
- **数据来源**: [火币 API](https://huobiapi.github.io/docs/spot/v1/cn/)
- **Flutter 文档**: [flutter.dev](https://flutter.dev/)

---

## 📮 联系方式

- **作者**: 911hzh
- **邮箱**: 911hzh@gmail.com
- **Issues**: [GitHub Issues](https://github.com/911hzh/ZHKLineFlutter/issues)

---

<div align="center">

**使用 ❤️ 和 Flutter 构建**

如果这个项目对你有帮助，请给一个 ⭐️ Star！

</div>
