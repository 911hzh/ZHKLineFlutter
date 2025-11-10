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

> 截图和 GIF 演示即将添加

![指标演示](lib/assets/show/flutter_indicator.gif)

![滚动流畅性演示](lib/assets/show/flutter_scrolling.gif)

![长按十字线演示](lib/assets/show/flutter_long_press.gif)

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

### 基础用法

```dart
import 'package:k_line_flutter/kline/widgets/KLineView.dart';

class MyKLinePage extends StatefulWidget {
  @override
  _MyKLinePageState createState() => _MyKLinePageState();
}

class _MyKLinePageState extends State<MyKLinePage> {
  List<KLineModel> _datas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. 获取 K 线数据
    final klineApi = KlineApi.shared;
    final rawData = await klineApi.getKLineModels(
      symbol: 'btcusdt',
      period: KLinePeriod.day1,
      size: 200,
    );

    // 2. 计算技术指标（自动完成）
    final modelsWithIndicators = DataUtil.toKLineModelsWithIndicators(
      rawData,
      KLinePeriod.day1,
    );

    setState(() {
      _datas = modelsWithIndicators;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('K 线图')),
      body: _datas.isEmpty
          ? Center(child: CircularProgressIndicator())
          : KLineView(
              datas: _datas,
              mainChartIndicatorSelection: [
                KLineTechnicalIndicatorType.ma,  // 显示 MA 指标
              ],
              secondChartIndicatorSelection: [
                KLineTechnicalIndicatorType.volume,  // 显示成交量
                KLineTechnicalIndicatorType.macd,    // 显示 MACD
              ],
              scale: KLineConfig.scale,
            ),
    );
  }
}
```

### 自定义配置

```dart
// 全局配置（单例模式）
final config = KLineConfig.shared;

// 蜡烛图样式
config.candleUpColor = Color(0xFFF14965);    // 涨势红色
config.candleDownColor = Color(0xFF00B066);  // 跌势绿色

// 技术指标颜色
config.ma5Color = Color(0xFFFFD700);   // MA5 金色
config.ma10Color = Color(0xFF00BFFF);  // MA10 蓝色
config.ma30Color = Color(0xFFDA70D6);  // MA30 紫色

// 缩放
KLineConfig.scale = 1.5;  // 1.5 倍缩放
```

---

## 📖 核心组件

### KLineView

主视图组件，包含完整的 K 线图表功能

```dart
KLineView(
  datas: List<KLineModel>,                              // K 线数据（必需）
  mainChartIndicatorSelection: List<KLineTechnicalIndicatorType>,  // 主图指标
  secondChartIndicatorSelection: List<KLineTechnicalIndicatorType>, // 副图指标
  scale: double,                                        // 缩放比例
)
```

### KLineModel

K 线数据模型，包含 OHLCV 数据和技术指标

```dart
class KLineModel {
  final double open;       // 开盘价
  final double close;      // 收盘价
  final double high;       // 最高价
  final double low;        // 最低价
  final double amount;     // 成交量
  final int id;            // 时间戳

  // 技术指标（由库自动计算）
  KLineTechnicalIndicatorsModel? kLineTechnicalIndicatorsModel;
}
```

### KLineConfig

配置类，控制图表外观和行为（单例模式）

```dart
class KLineConfig {
  static final KLineConfig shared = KLineConfig._internal();
  static double scale = 1.0;  // 全局缩放因子

  // 蜡烛图配置
  double get candleWidth => 8.5 * scale;
  double get candleSpace => 2.0 * scale;
  Color candleUpColor = Color(0xFFF14965);
  Color candleDownColor = Color(0xFF00B066);

  // 网格配置
  int crossHorCount = 5;      // 横向网格线数量
  int crossVerticalCount = 6; // 纵向网格线数量

  // ... 更多配置项
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

| 组件                        | 职责                   |
| --------------------------- | ---------------------- |
| **DataUtil**                | 技术指标计算引擎       |
| **KLineCrandleIndexUtil**   | 坐标位置计算工具       |
| **KLineMainPainter**        | 主图 CustomPainter     |
| **KLineSecondLayerPainter** | 副图 CustomPainter     |
| **IndicatorRenderer**       | 指标渲染器（策略模式） |

---

## 📊 技术指标

| 指标 | 说明               | 参数                          | 用途             |
| ---- | ------------------ | ----------------------------- | ---------------- |
| MA   | 移动平均线         | 周期: 5, 10, 30               | 判断趋势方向     |
| EMA  | 指数移动平均线     | 周期: 5, 10, 30               | 更敏感的趋势判断 |
| BOLL | 布林带             | 周期: 20, 倍数: 2             | 判断价格波动范围 |
| MACD | 指数平滑异同平均线 | 快线: 12, 慢线: 26, 信号线: 9 | 判断买卖时机     |
| KDJ  | 随机指标           | 周期: 9, K: 3, D: 3           | 判断超买超卖     |
| RSI  | 相对强弱指标       | 周期: 6, 12, 24               | 判断价格强弱     |
| WR   | 威廉指标           | 周期: 6, 10, 14               | 判断超买超卖     |
| VOL  | 成交量             | MA 周期: 5, 10                | 判断市场活跃度   |

---

## 📁 项目结构

```
lib/kline/
├── api/                      # 网络层
│   ├── ApiClient.dart        # Dio 网络请求
│   └── KlineApi.dart         # K 线 API（火币）
├── config/                   # 配置层
│   ├── ColorExtension.dart   # 颜色扩展
│   └── KLineConfig.dart      # K 线配置（单例）
├── models/                   # 数据模型
│   ├── KLineModel.dart
│   ├── KLinePositionModel.dart
│   ├── KLineTechnicalIndicatorsModel.dart
│   └── ...
├── utils/                    # 工具类
│   ├── DataUtil.dart         # 技术指标计算
│   └── KLineCrandleIndexUtil.dart  # 位置计算
└── widgets/                  # UI 组件
    ├── chart/                # 图表组件
    │   ├── KLineChartView.dart
    │   ├── KLineMainPainter.dart
    │   └── KLineSecondLayerPainter.dart
    ├── renderers/            # 指标渲染器
    │   ├── VolumeIndicatorRenderer.dart
    │   ├── MacdIndicatorRenderer.dart
    │   └── ...
    ├── KLineView.dart        # 主视图
    ├── ChartPage.dart        # K 线页面
    └── ...
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
| **配置**   | KLineConfig.shared | KLineConfig.shared    |
| **计算**   | DataUtil           | DataUtil              |

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
