# Bug 修复：滑动时主图指标数值消失

## 问题描述

**问题**: 滑动 K 线图时，主图指标数值（MA、EMA、BOLL）会消失，只有长按选中时才显示。

**期望行为**: 参考 Swift 版本，主图指标数值应该始终显示：

- 有选中数据时显示选中数据的指标
- 没有选中数据时显示第一条可见数据的指标
- 滑动时不应消失

## 根本原因

### Flutter 版本的问题

在 `k_line_view.dart` 的 `_onScroll()` 方法中：

```dart
void _onScroll() {
  setState(() {
    _scrollOffset = _scrollController.offset;
    _shouldShowCrossLine = false;
    _selectedKLineModel = null;  // ❌ 滑动时清除选中数据
    _updateDisplayData();
  });
}
```

然后传递给 `KLineChartView`：

```dart
KLineChartView(
  selectedKLineModel: _selectedKLineModel,  // ❌ 滑动时为 null
  ...
)
```

在 `k_line_chart_view.dart` 中：

```dart
// ❌ selectedKLineModel 为 null 时不显示
if (widget.selectedKLineModel != null && widget.mainChartIndicatorSelection.isNotEmpty)
  KMainIndicatorTextView(...)
```

**结果**: 滑动时 `_selectedKLineModel` 变为 `null`，导致主图指标数值不显示。

### Swift 版本的正确实现

在 `KLineView.swift` 的 `drawUI()` 方法中：

```swift
// ✅ 没有选中数据时使用第一条数据
let modelToDisplay = selectedKLineModel ?? datas.first
updateMainChartIndicators(with: modelToDisplay)
```

**结果**: 滑动时即使 `selectedKLineModel` 为 `nil`，也会显示 `datas.first` 的指标。

## 修复方案

### 修改 1: k_line_view.dart (第 159 行)

**修改前:**

```dart
KLineChartView(
  selectedKLineModel: _selectedKLineModel,
  ...
)
```

**修改后:**

```dart
KLineChartView(
  // 如果没有选中数据，使用第一条可见数据（类似 Swift 版本）
  selectedKLineModel: _selectedKLineModel ?? (_showDatas.isNotEmpty ? _showDatas.first : null),
  ...
)
```

### 修改 2: k_line_chart_view.dart (第 89 行注释更新)

更新注释说明行为：

```dart
// 主图指标数值显示（始终显示，即使没有选中数据也显示第一条数据的指标）
if (widget.selectedKLineModel != null && widget.mainChartIndicatorSelection.isNotEmpty)
  KMainIndicatorTextView(...)
```

## 行为对比

### 修复前

| 场景     | 主图指标数值显示 |
| -------- | ---------------- |
| 初始加载 | ❌ 不显示        |
| 长按选中 | ✅ 显示选中数据  |
| 取消选中 | ❌ 不显示        |
| 滑动图表 | ❌ 不显示        |

### 修复后

| 场景     | 主图指标数值显示      |
| -------- | --------------------- |
| 初始加载 | ✅ 显示第一条数据     |
| 长按选中 | ✅ 显示选中数据       |
| 取消选中 | ✅ 显示第一条可见数据 |
| 滑动图表 | ✅ 显示第一条可见数据 |

## 技术细节

### 为什么使用 `_showDatas.first` 而不是 `widget.datas.first`？

- `_showDatas` 是当前可见范围内的数据
- `widget.datas` 是全部数据
- 使用 `_showDatas.first` 可以确保显示的是当前屏幕可见的第一条数据的指标

### 为什么不需要修改副图指标？

副图指标的渲染器（如 `MACDIndicatorRenderer`）中的 `paintIndicatorValueLabels` 方法会接收到同样的 `selectedKLineModel`，因此自动获得了相同的修复效果。

```dart
// macd_indicator_renderer.dart
@override
void paintIndicatorValueLabels(
  Canvas canvas,
  Size size,
  KLineTechnicalIndicatorType indicatorType,
  List<KLineModel> klineModels,
  KLineModel? selectedKLineModel,  // ✅ 现在总是有值（选中的或第一条）
) {
  if (selectedKLineModel == null) return;
  // ... 绘制指标数值
}
```

## 测试验证

### 测试步骤

1. **初始状态测试**

   - 打开 K 线图页面
   - ✅ 验证主图左上角显示第一条数据的指标值

2. **长按选中测试**

   - 长按图表选中一根 K 线
   - ✅ 验证显示选中 K 线的指标值
   - ✅ 验证十字线正确显示

3. **取消选中测试**

   - 点击空白区域或抬起手指
   - ✅ 验证十字线消失
   - ✅ 验证主图指标数值**不消失**，显示第一条可见数据

4. **滑动测试**

   - 左右滑动图表
   - ✅ 验证主图指标数值**持续显示**
   - ✅ 验证显示的是当前可见范围第一条数据的指标
   - ✅ 验证十字线不显示

5. **指标切换测试**
   - 切换 MA/EMA/BOLL 指标
   - ✅ 验证指标数值正确切换
   - ✅ 验证滑动时仍然显示

## 影响范围

### 修改的文件

- `lib/kline/widgets/k_line_view.dart` (1 行代码修改)
- `lib/kline/widgets/chart/k_line_chart_view.dart` (1 行注释更新)

### 影响的功能

- ✅ 主图指标数值显示（MA/EMA/BOLL）
- ✅ 副图指标数值显示（MACD/VOL/KDJ/RSI/WR）
- ⚠️ 十字线显示逻辑（未改变，仍然只在长按时显示）

### 不影响的功能

- ❌ 十字线显示/隐藏逻辑
- ❌ 手势处理逻辑
- ❌ 图表渲染逻辑
- ❌ 指标计算逻辑

## 与 Swift 版本的一致性

| 功能               | Swift 版本 | Flutter 版本（修复前） | Flutter 版本（修复后） |
| ------------------ | ---------- | ---------------------- | ---------------------- |
| 选中时显示指标     | ✅         | ✅                     | ✅                     |
| 默认显示第一条数据 | ✅         | ❌                     | ✅                     |
| 滑动时持续显示     | ✅         | ❌                     | ✅                     |
| 取消选中后显示     | ✅         | ❌                     | ✅                     |

✅ **修复后完全一致**

## 相关文档

- `INDICATOR_VALUE_LABELS_IMPLEMENTATION.md` - 指标数值显示功能实现文档
- `FEATURE_COMPARISON.md` - Swift vs Flutter 功能对比文档

## 修复日期

2025-10-15

## 修复者

AI Assistant (基于用户反馈)
