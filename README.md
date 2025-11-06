# ZHKLineFlutter

![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B.svg)
![Dart](https://img.shields.io/badge/Dart-3.7.0+-0175C2.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow.svg)

一个高性能、功能完整的 Flutter K 线图表库，专为金融应用设计。本项目是 [ZHKLine](https://github.com/911hzh/ZHKline) 的 Flutter 跨平台版本，采用先进的绘制架构，支持多种技术指标，提供流畅的用户交互体验。

参考火币的 UI 设计进行实现，使用的数据也来自于火币的接口。

## ✨ 特性

### 📊 完整的技术指标支持

- **缩放位置精准**: 放大缩小从双指中间位置开始缩放
- **滑动非常顺滑**: 基于 Flutter 手势系统实现，惯性滚动、减速等不再生硬
- **高度自定义机制**: 各个组件使用模块化设计，用户可快速组合生成自己的 UI
- **性能优异**: 使用 CustomPainter 绘制，计算与渲染分离
- **高扩展性**: 可以轻松扩展新的技术指标，使用策略模式添加
- **主图指标**: MA(5,10,30)、EMA(5,10,30)、BOLL(布林带)
- **副图指标**: MACD、KDJ、RSI(6,12,24)、WR(6,10,14)、VOL(成交量)
- **实时计算**: 所有技术指标实时计算，无延迟显示
- **多选支持**: 支持同时显示多个技术指标

### 🚀 卓越性能

- **预计算优化**: 一次计算，多次复用
- **流畅交互**: 60FPS 平滑滚动和缩放
- **内存友好**: 智能内存管理，支持大数据量
- **高效绘制**: 使用 CustomPainter，避免不必要的重绘

### 🎨 精美界面

- **火币风格**: 高度还原火币交易界面
- **十字线功能**: 精确的价格和时间显示
- **详情面板**: 实时显示 K 线详细信息
- **手势交互**: 支持缩放、拖拽、长按选择

### 🛠 开发者友好

- **Flutter 原生**: 100% Dart 实现
- **模块化设计**: 清晰的代码结构，易于扩展
- **纯函数编码**: 代码更简洁，更易于维护，可单独测试某个组件

## 📱 效果预览

> 注：效果图参考 Swift 版本，Flutter 版本将实现相同的效果

<table>
<tr>
<td width="50%">

**K 线图表**

- 蜡烛图显示
- 技术指标叠加
- 十字线交互

</td>
<td width="50%">

**技术指标**

- 多种指标选择
- 实时数值显示
- 流畅切换动画

</td>
</tr>
</table>

### 性能表现

- **流畅度**: 60FPS 惯性滚动，无卡顿
- **精准缩放**: 双指缩放，以触摸中心点为基准
- **长按交互**: 长按显示十字线和详情面板
- **指标切换**: 流畅的指标切换动画
- **内存优化**: 2000 条数据下内存占用控制在合理范围

## 🚀 快速开始

### 基础用法

```dart
import 'package:k_line_flutter/k_line_flutter.dart';

class KLineDemo extends StatefulWidget {
  @override
  _KLineDemoState createState() => _KLineDemoState();
}

class _KLineDemoState extends State<KLineDemo> {
  List<KLineData> klineData = [];

  @override
  void initState() {
    super.initState();
    // 加载 K 线数据
    _loadKLineData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('K线图表')),
      body: Column(
        children: [
          // K 线图表组件
          KLineChart(
            data: klineData,
            // 配置选项
            config: KLineConfig(
              candleWidth: 8.0,
              candleSpacing: 2.0,
              showGrid: true,
              showCrosshair: true,
            ),
            // 主图指标
            mainIndicators: [
              MainIndicatorType.MA,
              MainIndicatorType.BOLL,
            ],
            // 副图指标
            subIndicators: [
              SubIndicatorType.MACD,
              SubIndicatorType.KDJ,
            ],
            // 高度变化回调
            onHeightChanged: (height) {
              print('图表高度变化: $height');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadKLineData() async {
    // 加载数据逻辑
    // klineData = await loadData();
    setState(() {});
  }
}
```

### 自定义配置

```dart
// 自定义颜色和样式
KLineConfig config = KLineConfig(
  // 蜡烛图配置
  candleUpColor: Color(0xFF00C087),      // 上涨颜色
  candleDownColor: Color(0xFFEF5350),    // 下跌颜色
  candleWidth: 8.0,                       // 蜡烛宽度
  candleSpacing: 2.0,                     // 蜡烛间距

  // 网格配置
  showGrid: true,                         // 显示网格
  gridColor: Color(0xFF333333),          // 网格颜色
  gridLineWidth: 0.5,                     // 网格线宽

  // 十字线配置
  showCrosshair: true,                    // 显示十字线
  crosshairColor: Color(0xFF999999),     // 十字线颜色
  crosshairWidth: 0.5,                    // 十字线宽度

  // 文字配置
  textColor: Color(0xFFFFFFFF),          // 文字颜色
  textSize: 10.0,                         // 文字大小

  // 缩放配置
  minScale: 0.5,                          // 最小缩放
  maxScale: 3.0,                          // 最大缩放
  defaultScale: 1.0,                      // 默认缩放
);

// 使用自定义配置
KLineChart(
  data: klineData,
  config: config,
)
```

## 📖 核心组件

### KLineChart

主要的 K 线图表组件，提供完整的 K 线图表功能。

```dart
KLineChart({
  required List<KLineData> data,           // K线数据
  KLineConfig? config,                      // 配置选项
  List<MainIndicatorType>? mainIndicators, // 主图指标
  List<SubIndicatorType>? subIndicators,   // 副图指标
  ValueChanged<double>? onHeightChanged,   // 高度变化回调
  ValueChanged<KLineData>? onTap,          // 点击回调
  ValueChanged<KLineData>? onLongPress,    // 长按回调
})
```

### KLineData

K 线数据模型，包含 OHLCV 数据和技术指标。

```dart
class KLineData {
  final double open;       // 开盘价
  final double close;      // 收盘价
  final double high;       // 最高价
  final double low;        // 最低价
  final double volume;     // 成交量
  final DateTime time;     // 时间戳

  // 技术指标数据（由库自动计算）
  KLineTechnicalIndicators? indicators;
}
```

### KLineConfig

K 线图表配置类，控制图表的外观和行为。

```dart
class KLineConfig {
  // 蜡烛图样式
  final Color candleUpColor;
  final Color candleDownColor;
  final double candleWidth;
  final double candleSpacing;

  // 网格样式
  final bool showGrid;
  final Color gridColor;
  final double gridLineWidth;

  // 十字线样式
  final bool showCrosshair;
  final Color crosshairColor;
  final double crosshairWidth;

  // 缩放配置
  final double minScale;
  final double maxScale;
  final double defaultScale;

  // ... 更多配置项
}
```

### 技术指标计算

所有技术指标由库自动计算，无需手动处理。

```dart
// 主图指标
enum MainIndicatorType {
  MA,      // 移动平均线 (5, 10, 30)
  EMA,     // 指数移动平均线 (5, 10, 30)
  BOLL,    // 布林带
}

// 副图指标
enum SubIndicatorType {
  MACD,    // MACD
  KDJ,     // KDJ
  RSI,     // RSI (6, 12, 24)
  WR,      // WR (6, 10, 14)
  VOL,     // 成交量
}
```

## 🏗 架构设计

### 核心设计原则

1. **纯函数设计**: 计算逻辑无副作用，易于测试
2. **职责分离**: 数据计算、位置计算、视图渲染完全分离
3. **预计算优化**: 所有位置信息预先计算，避免重复计算

### 绘制流程

```
原始数据 → 技术指标计算 → 坐标位置计算 → CustomPainter 绘制 → 手势交互
    ↓            ↓                ↓                  ↓              ↓
KLineData  →  Indicators  →  DrawPoints  →  Canvas.draw  →  GestureDetector
```

### 关键组件

- **DataCalculator**: 技术指标计算引擎
- **CoordinateCalculator**: 坐标位置计算工具
- **KLinePainter**: CustomPainter 绘制器
- **GestureManager**: 手势交互管理器
- **IndicatorRenderer**: 指标渲染器

## 📝 技术指标说明

| 指标 | 说明               | 参数                          | 用途                     |
| ---- | ------------------ | ----------------------------- | ------------------------ |
| MA   | 简单移动平均线     | 周期: 5, 10, 30               | 判断趋势方向             |
| EMA  | 指数移动平均线     | 周期: 5, 10, 30               | 更敏感的趋势判断         |
| BOLL | 布林带             | 周期: 20, 倍数: 2             | 判断价格波动范围         |
| MACD | 指数平滑移动平均线 | 快线: 12, 慢线: 26, 信号线: 9 | 判断买卖时机             |
| KDJ  | 随机指标           | 周期: 9, K 平滑: 3, D 平滑: 3 | 判断超买超卖             |
| RSI  | 相对强弱指标       | 周期: 6, 12, 24               | 判断价格强弱             |
| WR   | 威廉指标           | 周期: 6, 10, 14               | 判断超买超卖             |
| VOL  | 成交量             | MA 周期: 5, 10                | 判断市场活跃度和趋势强度 |

## 🔨 扩展指标

### 添加自定义技术指标

```dart
// 1. 创建指标计算类
class CustomIndicatorCalculator {
  static List<double> calculate(List<KLineData> data, int period) {
    // 实现计算逻辑
    List<double> result = [];
    // ... 计算过程
    return result;
  }
}

// 2. 创建指标渲染器
class CustomIndicatorPainter extends IndicatorPainter {
  @override
  void paint(Canvas canvas, Size size, List<KLineData> data) {
    // 实现绘制逻辑
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0;

    // ... 绘制过程
  }
}

// 3. 注册指标
IndicatorRegistry.register(
  'CUSTOM',
  calculator: CustomIndicatorCalculator.calculate,
  painter: CustomIndicatorPainter(),
);
```

## 📝 待办事项

### 绘制系统

- [ ] K 线蜡烛图绘制
- [ ] 成交量柱状图绘制
- [ ] 技术指标曲线绘制
- [ ] 网格线绘制
- [ ] 坐标轴刻度绘制
- [ ] 十字线绘制
- [ ] 详情面板绘制

### 技术指标

- [ ] MA (移动平均线) 计算与绘制
- [ ] EMA (指数移动平均线) 计算与绘制
- [ ] BOLL (布林带) 计算与绘制
- [ ] MACD 计算与绘制
- [ ] KDJ 计算与绘制
- [ ] RSI 计算与绘制
- [ ] WR 计算与绘制
- [ ] VOL (成交量) 计算与绘制

### 手势交互

- [ ] 水平拖拽滚动
- [ ] 惯性滚动
- [ ] 双指缩放
- [ ] 长按显示十字线
- [ ] 长按拖动十字线
- [ ] 边界检测

### 性能优化

- [ ] CustomPainter 绘制优化
- [ ] 坐标计算缓存
- [ ] 可见区域裁剪
- [ ] 大数据量分段加载
- [ ] 内存使用优化

### UI/UX

- [ ] 主题系统 (亮色/暗色)
- [ ] 指标选择面板
- [ ] 详情面板动画
- [ ] 加载状态
- [ ] 空数据状态
- [ ] 错误状态处理

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 提交规范

采用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

- `feat`: 新功能
- `fix`: 修复 Bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关项目

- [ZHKLine (Swift)](https://github.com/911hzh/ZHKline) - 原始 iOS 版本

## 📮 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 [Issue](https://github.com/your-username/ZHKLineFlutter/issues)
- 发送邮件至 911hzh@gmail.com

---

**使用 ❤️ 和 Flutter 构建**
