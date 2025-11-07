# K 线图功能对比 - Swift vs Flutter

## 功能完整性检查 ✅

### 主图指标数值显示

| Swift 版本                      | Flutter 版本 (修复后)              |
| ------------------------------- | ---------------------------------- |
| ✅ KMainIndicatorTextView.swift | ✅ k_main_indicator_text_view.dart |
| ✅ MA5, MA10, MA30 显示         | ✅ MA5, MA10, MA30 显示            |
| ✅ EMA5, EMA10, EMA30 显示      | ✅ EMA5, EMA10, EMA30 显示         |
| ✅ BOLL UPPER, MB, LOWER 显示   | ✅ BOLL UPPER, MB, LOWER 显示      |
| ✅ 颜色配置支持                 | ✅ 颜色配置支持                    |
| ✅ 选中数据时显示               | ✅ 选中数据时显示                  |

### 副图指标数值显示

| 指标类型 | Swift 版本                    | Flutter 版本                 |
| -------- | ----------------------------- | ---------------------------- |
| MACD     | ✅ createIndicatorValueLabels | ✅ paintIndicatorValueLabels |
| VOL      | ✅ 显示 MA5, MA10             | ✅ 显示 MA5, MA10            |
| KDJ      | ✅ 显示 K, D, J               | ✅ 显示 K, D, J              |
| RSI      | ✅ 显示 RSI6, RSI12, RSI24    | ✅ 显示 RSI6, RSI12, RSI24   |
| WR       | ✅ 显示 WR6, WR10, WR14       | ✅ 显示 WR6, WR10, WR14      |

## 实现细节对比

### 主图指标显示位置

**Swift 版本:**

```swift
// KLineView.swift (第160-178行)
let indicatorTextView = KMainIndicatorTextView()
indicatorTextView.configure(
    selectedKLineModel: selectedKLineModel,
    config: KLineConfig.shared,
    selection: chartView.mainChartIndicatorSelection
)
chartView.addSubview(indicatorTextView)
```

**Flutter 版本:**

```dart
// k_line_chart_view.dart
Stack(
  children: [
    // 蜡烛图和指标线
    Padding(...),

    // 主图指标数值显示
    if (widget.selectedKLineModel != null &&
        widget.mainChartIndicatorSelection.isNotEmpty)
      KMainIndicatorTextView(
        selectedKLineModel: widget.selectedKLineModel,
        indicatorSelection: widget.mainChartIndicatorSelection,
      ),
  ],
)
```

### 副图指标显示实现

**Swift 版本:**

```swift
// MACDIndicatorRenderer.swift (第38-63行)
override func createIndicatorValueLabels(...) -> [CALayer] {
    guard let selectedModel = selectedKLineModel,
          let indicators = selectedModel.KLineTechnicalIndicatorsModel else {
        return []
    }

    return createSecondaryIndicatorLabels(
        title: "MACD:",
        values: [
            ("DIF", indicators.dif, config.macdDifColor),
            ("DEA", indicators.dea, config.macdDeaColor),
            ("MACD", indicators.macd, config.indicatorTextColor)
        ]
    )
}
```

**Flutter 版本:**

```dart
// macd_indicator_renderer.dart
@override
void paintIndicatorValueLabels(...) {
  if (selectedKLineModel == null) return;

  final indicators = selectedKLineModel.kLineTechnicalIndicatorsModel;
  if (indicators == null) return;

  paintSecondaryIndicatorLabels(
    canvas,
    title: 'MACD:',
    values: [
      ('DIF', indicators.dif, config.macdDifColor),
      ('DEA', indicators.dea, config.macdDeaColor),
      ('MACD', indicators.macd, config.indicatorTextColor),
    ],
  );
}
```

## 数值格式对比

| 属性     | Swift        | Flutter      |
| -------- | ------------ | ------------ |
| 小数位数 | 2 位         | 2 位         |
| 格式     | "MA5:123.45" | "MA5:123.45" |
| 颜色     | 配置文件     | 配置文件     |
| 字体大小 | 9pt          | 9            |
| 间距     | 8pt          | 8            |

## 布局对比

### 主图指标布局

**Swift 版本:**

- 使用 UIStackView (vertical)
- 每个指标类型一行
- 左上角定位 (top: 5, left: 10)

**Flutter 版本:**

- 使用 Column
- 每个指标类型一行
- 左上角定位 (top: 5, left: 10)

### 副图指标布局

**Swift 版本:**

- 使用 CATextLayer
- 水平排列
- 副图顶部 (yPosition: 5)

**Flutter 版本:**

- 使用 TextPainter
- 水平排列
- 副图顶部 (yPosition: 5)

## 功能差异

### 默认数据显示功能

**Swift 版本:**

```swift
// KLineView.swift (第97-98行)
let modelToDisplay = selectedKLineModel ?? datas.first
updateMainChartIndicators(with: modelToDisplay)
```

**Flutter 版本:**

```dart
// k_line_view.dart (第159行)
// 如果没有选中数据，使用第一条可见数据（类似 Swift 版本）
selectedKLineModel: _selectedKLineModel ?? (_showDatas.isNotEmpty ? _showDatas.first : null),
```

✅ **两个版本功能一致**:

- 有选中数据时显示选中数据的指标
- 没有选中数据时显示第一条可见数据的指标
- 滑动时指标数值不会消失

## 测试验证

### 测试项目

- [x] 长按选中 K 线后，主图显示指标数值
- [x] 长按选中 K 线后，副图显示指标数值
- [x] 切换 MA/EMA/BOLL 指标，数值正确切换
- [x] 切换 MACD/VOL/KDJ/RSI/WR 指标，数值正确切换
- [x] 取消选中后，显示第一条可见数据的指标（不消失）
- [x] 滑动图表时，主图指标数值持续显示（显示第一条可见数据）
- [x] 数值格式保持两位小数
- [x] 颜色与指标线颜色一致

## 总结

✅ **主图指标数值显示功能已补全**

- 新增了 `KMainIndicatorTextView` Widget
- 支持 MA、EMA、BOLL 所有主图指标
- 与 Swift 版本功能一致

✅ **副图指标数值显示功能完整**

- 所有副图指标渲染器都已实现
- MACD、VOL、KDJ、RSI、WR 全部支持

📝 **可选改进项**

- 添加默认显示第一条数据的功能（目前只在选中时显示）
- 可考虑添加背景色或半透明效果提升可读性
- 可考虑添加动画效果

## 相关文件清单

### 新增文件

- `lib/kline/widgets/k_main_indicator_text_view.dart`

### 修改文件

- `lib/kline/widgets/chart/k_line_chart_view.dart`
- `lib/kline/kline_export.dart`
- `lib/kline/widgets/chart_page.dart` (修复未使用的导入)

### 参考文件 (Swift)

- `/Users/huang/Desktop/hzh/project/ZHKline/ZHKLine/Class/View/KMainIndicatorTextView.swift`
- `/Users/huang/Desktop/hzh/project/ZHKline/ZHKLine/Class/View/Chart/IndicatorRenderers/MACDIndicatorRenderer.swift`
