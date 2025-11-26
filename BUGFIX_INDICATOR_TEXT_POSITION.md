# Bug 修复：主图指标文本位置跟随滚动移动

## 问题描述

**问题**: 主图指标数值文本（MA、EMA、BOLL）会随着图表滚动而移动，导致 dx 偏移位置不正确。

**期望行为**: 主图指标文本应该固定在屏幕左上角，不随图表滚动而移动（类似网格线和指标选择器）。

## 根本原因

### Flutter 版本的问题（修复前）

在 `k_line_chart_view.dart` 中，`KMainIndicatorTextView` 被放在可滚动的内容里面：

```dart
// ❌ 错误的位置：在 KLineChartView 内部
Widget _buildMainChart() {
  return Positioned(
    child: Stack(
      children: [
        // 蜡烛图和指标线
        CustomPaint(...),

        // ❌ 这个会随着 ScrollView 一起滚动
        KMainIndicatorTextView(...),
      ],
    ),
  );
}
```

而 `KLineChartView` 是在 `SingleChildScrollView` 里面的：

```dart
// k_line_view.dart
SingleChildScrollView(
  controller: _scrollController,
  child: KLineChartView(...)  // ❌ 里面的所有内容都会滚动
)
```

**结果**: 当用户左右滚动图表时，指标文本也会跟着移动，导致 dx 位置错误。

### Swift 版本的正确实现

在 Swift 版本中，`KMainIndicatorTextView` 是添加到 `chartView` 上的，而 `chartView` 本身的位置会根据 scrollView 的 offset 调整，但文本相对于 chartView 是固定的。

## 修复方案

### 方案概述

将 `KMainIndicatorTextView` 从可滚动内容中移出，放到固定的 Stack 层中，使其不随滚动移动。

### 修改 1: k_line_chart_view.dart

**删除内部的指标文本显示**

修改前（包含指标文本）:

```dart
Widget _buildMainChart() {
  return Positioned(
    child: Stack(
      children: [
        CustomPaint(...),
        KMainIndicatorTextView(...),  // ❌ 删除这个
      ],
    ),
  );
}
```

修改后（移除指标文本）:

```dart
Widget _buildMainChart() {
  return Positioned(
    child: Padding(
      padding: config.crandleInsets,
      child: CustomPaint(...),  // ✅ 只保留蜡烛图绘制
    ),
  );
}
```

同时删除 `k_main_indicator_text_view.dart` 的导入。

### 修改 2: k_line_view.dart

**添加固定的指标文本层**

1. 添加导入：

```dart
import 'k_main_indicator_text_view.dart';
```

2. 在 Stack 中添加固定层：

```dart
Stack(
  children: [
    // 固定的网格线层
    _buildGridLayer(),

    // 可滚动的内容层
    SingleChildScrollView(...),

    // ✅ 新增：主图指标文本层（固定不滚动）
    _buildMainIndicatorTextLayer(),

    // 技术指标选择器
    Positioned(...),
  ],
)
```

3. 实现 `_buildMainIndicatorTextLayer()` 方法：

```dart
/// 构建主图指标文本层（固定不滚动）
Widget _buildMainIndicatorTextLayer() {
  final config = KLineConfig.shared;
  final selectedModel = _selectedKLineModel ??
      (_showDatas.isNotEmpty ? _showDatas.first : null);

  if (selectedModel == null || _mainChartIndicators.isEmpty) {
    return const SizedBox.shrink();
  }

  return Positioned(
    left: config.chartViewPadding.left + 10,  // ✅ 固定位置
    top: 5,                                     // ✅ 固定位置
    child: IgnorePointer(                      // ✅ 不响应手势
      child: KMainIndicatorTextView(
        selectedKLineModel: selectedModel,
        indicatorSelection: _mainChartIndicators,
      ),
    ),
  );
}
```

## 技术细节

### 为什么使用 Positioned？

- `Positioned` 组件在 Stack 中定义固定的位置
- 位置相对于父 Stack（整个 KLineView）而不是滚动内容
- 不受 `SingleChildScrollView` 滚动影响

### 为什么使用 IgnorePointer？

- 指标文本只用于显示，不需要响应手势
- 使用 `IgnorePointer` 让手势事件穿透到下层
- 确保不干扰图表的滑动和长按操作

### 位置计算

```dart
left: config.chartViewPadding.left + 10
```

- `chartViewPadding.left`: 图表左侧边距
- `+ 10`: 额外的内边距，与主图内容保持一致

### 层级结构对比

**修复前**:

```
Stack
├── 网格线层（固定）
├── SingleChildScrollView（可滚动）
│   └── KLineChartView
│       ├── 蜡烛图
│       └── 指标文本 ❌ 会滚动
└── 指标选择器（固定）
```

**修复后**:

```
Stack
├── 网格线层（固定）
├── SingleChildScrollView（可滚动）
│   └── KLineChartView
│       └── 蜡烛图
├── 指标文本层（固定）✅ 不滚动
└── 指标选择器（固定）
```

## 行为对比

### 修复前

| 操作     | 指标文本位置            |
| -------- | ----------------------- |
| 初始加载 | 左上角（正确）          |
| 向右滚动 | ❌ 跟着向左移动（错误） |
| 向左滚动 | ❌ 跟着向右移动（错误） |
| 长按选中 | ❌ 随内容滚动（错误）   |

### 修复后

| 操作     | 指标文本位置    |
| -------- | --------------- |
| 初始加载 | ✅ 固定在左上角 |
| 向右滚动 | ✅ 固定在左上角 |
| 向左滚动 | ✅ 固定在左上角 |
| 长按选中 | ✅ 固定在左上角 |

## 测试验证

### 测试步骤

1. **初始位置测试**

   - 打开 K 线图页面
   - ✅ 验证指标文本在左上角固定位置

2. **向右滚动测试**

   - 向右滑动图表（查看早期数据）
   - ✅ 验证指标文本**不移动**，保持在左上角
   - ✅ 验证显示的数值随着第一条可见数据变化

3. **向左滚动测试**

   - 向左滑动图表（查看最新数据）
   - ✅ 验证指标文本**不移动**，保持在左上角
   - ✅ 验证显示的数值随着第一条可见数据变化

4. **长按选中测试**

   - 长按图表选中一根 K 线
   - ✅ 验证指标文本位置不变
   - ✅ 验证显示选中 K 线的指标数值

5. **快速滑动测试**
   - 快速滑动图表（惯性滚动）
   - ✅ 验证指标文本始终固定在左上角
   - ✅ 验证没有卡顿或跳动

## 影响范围

### 修改的文件

1. `lib/kline/widgets/k_line_view.dart`

   - 添加 `_buildMainIndicatorTextLayer()` 方法
   - 在 Stack 中添加固定的指标文本层
   - 添加 `k_main_indicator_text_view.dart` 导入

2. `lib/kline/widgets/chart/k_line_chart_view.dart`
   - 从 `_buildMainChart()` 中移除指标文本显示
   - 删除 `k_main_indicator_text_view.dart` 导入

### 影响的功能

- ✅ 主图指标文本位置（固定显示）
- ✅ 滚动时指标数值更新（显示第一条可见数据）
- ⚠️ 需要确保 `IgnorePointer` 不影响手势处理

### 不影响的功能

- ❌ 蜡烛图渲染
- ❌ 副图指标显示
- ❌ 十字线显示
- ❌ 手势处理逻辑
- ❌ 指标计算

## 与 Swift 版本的一致性

| 特性             | Swift 版本 | Flutter 版本（修复前） | Flutter 版本（修复后） |
| ---------------- | ---------- | ---------------------- | ---------------------- |
| 指标文本固定位置 | ✅         | ❌                     | ✅                     |
| 滚动时不移动     | ✅         | ❌                     | ✅                     |
| 数值随数据更新   | ✅         | ✅                     | ✅                     |
| 位置在左上角     | ✅         | ✅                     | ✅                     |

✅ **修复后完全一致**

## 相关问题修复

此修复依赖于之前的 Bug 修复：

- [BUGFIX_INDICATOR_VALUES_DISAPPEAR.md](./BUGFIX_INDICATOR_VALUES_DISAPPEAR.md) - 修复滑动时指标数值消失的问题

两个修复共同确保：

1. 指标数值始终显示（不消失）
2. 指标文本位置固定（不移动）

## 修复日期

2025-10-15

## 修复者

AI Assistant (基于用户反馈："偏移位置不对，应该是 dx 错了")
