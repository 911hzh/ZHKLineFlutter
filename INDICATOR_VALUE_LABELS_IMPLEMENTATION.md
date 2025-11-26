# 指标数值标签显示功能实现

## 问题描述

对比 Swift 版本的 K 线图实现，Flutter 版本缺失了主图和副图中选中数据或默认数据的指标数值显示功能。

## Swift 版本的实现

### 1. 主图指标数值显示

- **文件**: `KMainIndicatorTextView.swift`
- **功能**:
  - 使用 UIStackView 布局显示主图指标数值
  - 支持 MA、EMA、BOLL 指标的数值显示
  - 根据选中的 K 线数据显示对应的指标数值
  - 如果没有选中数据，显示第一条数据的指标

### 2. 副图指标数值显示

- **文件**: `MACDIndicatorRenderer.swift` (createIndicatorValueLabels 方法)
- **功能**:
  - 只在有选中 K 线数据时显示指标数值
  - 在副图顶部显示 MACD、VOL、KDJ 等指标的数值
  - 每个数值使用不同的颜色标识

## Flutter 版本的修复

### 1. 新增主图指标数值显示组件

**文件**: `lib/kline/widgets/k_main_indicator_text_view.dart`

**实现内容**:

- 创建了 `KMainIndicatorTextView` Widget
- 使用 Flutter 的 Column 和 Row 布局
- 支持以下指标的数值显示：
  - **MA**: MA5, MA10, MA30
  - **EMA**: EMA5, EMA10, EMA30
  - **BOLL**: UPPER, MB, LOWER
- 每个指标数值都使用配置中定义的颜色
- 只在有选中的 K 线数据时显示

**主要特性**:

```dart
// 显示位置：图表左上角
Positioned(
  top: 5,
  left: 10,
  ...
)

// 数值格式：指标名:数值 (保留两位小数)
'MA5:123.45'
```

### 2. 集成到主图视图

**文件**: `lib/kline/widgets/k_line_view.dart`

**修改内容**:

- 在 `k_line_view.dart` 的主 Stack 中添加固定的指标文本层
- 使用 `_buildMainIndicatorTextLayer()` 方法构建固定层
- 指标文本不在可滚动内容中，而是固定在屏幕上
- 使用 `IgnorePointer` 避免干扰手势处理

**实现代码**:

```dart
// k_line_view.dart
Stack(
  children: [
    // 固定的网格线层
    _buildGridLayer(),

    // 可滚动的内容层
    SingleChildScrollView(...),

    // 主图指标文本层（固定不滚动）
    _buildMainIndicatorTextLayer(),

    // 技术指标选择器
    Positioned(...),
  ],
)

/// 构建主图指标文本层（固定不滚动）
Widget _buildMainIndicatorTextLayer() {
  final config = KLineConfig.shared;
  final selectedModel = _selectedKLineModel ??
      (_showDatas.isNotEmpty ? _showDatas.first : null);

  if (selectedModel == null || _mainChartIndicators.isEmpty) {
    return const SizedBox.shrink();
  }

  return Positioned(
    left: config.chartViewPadding.left + 10,  // 固定位置
    top: 5,                                     // 固定位置
    child: IgnorePointer(                      // 不响应手势
      child: KMainIndicatorTextView(
        selectedKLineModel: selectedModel,
        indicatorSelection: _mainChartIndicators,
      ),
    ),
  );
}
```

**关键点**:

- 指标文本层与网格线层、指标选择器处于同一层级
- 不在 `SingleChildScrollView` 内部，不会随滚动移动
- 使用 `Positioned` 固定位置，相对于整个 KLineView
- 使用 `IgnorePointer` 让手势事件穿透到下层

### 3. 副图指标数值显示（已有）

所有副图指标渲染器都已实现 `paintIndicatorValueLabels` 方法：

- ✅ **MACDIndicatorRenderer**: 显示 DIF, DEA, MACD
- ✅ **VolumeIndicatorRenderer**: 显示 MA5, MA10
- ✅ **KDJIndicatorRenderer**: 显示 K, D, J
- ✅ **RSIIndicatorRenderer**: 显示 RSI6, RSI12, RSI24
- ✅ **WRIndicatorRenderer**: 显示 WR6, WR10, WR14

## 功能对比

| 功能               | Swift 版本 | Flutter 版本 (修复前) | Flutter 版本 (修复后) |
| ------------------ | ---------- | --------------------- | --------------------- |
| 主图指标数值显示   | ✅         | ❌                    | ✅                    |
| 副图指标数值显示   | ✅         | ✅                    | ✅                    |
| 选中数据时显示     | ✅         | ✅                    | ✅                    |
| 默认显示第一条数据 | ✅         | ❌                    | ✅                    |
| 滑动时持续显示     | ✅         | ❌                    | ✅                    |

## 注意事项

### 显示时机

- **主图指标**:
  - 有选中 K 线数据时显示选中数据的指标
  - 没有选中数据时显示第一条可见数据的指标（与 Swift 版本一致）
- **副图指标**:
  - 有选中 K 线数据时显示选中数据的指标
  - 没有选中数据时显示第一条可见数据的指标（与 Swift 版本一致）

**实现代码** (`k_line_view.dart` 第 159 行)：

```dart
// 如果没有选中数据，使用第一条可见数据（类似 Swift 版本）
selectedKLineModel: _selectedKLineModel ?? (_showDatas.isNotEmpty ? _showDatas.first : null),
```

这样确保了滑动时主图指标数值不会消失，始终显示当前可见范围内第一条数据的指标值。

### 样式配置

所有颜色配置都来自 `KLineConfig`，确保与主图和副图的指标线颜色保持一致。

### 性能优化

- 使用 `StatelessWidget` 避免不必要的状态管理
- 只在需要时才显示组件（通过条件渲染）
- 使用 `const` 构造函数提高性能

## 测试建议

1. **选中 K 线数据**

   - 长按图表选中一根 K 线
   - 检查主图和副图是否都显示了对应的指标数值

2. **切换指标**

   - 切换不同的主图指标（MA/EMA/BOLL）
   - 切换不同的副图指标（MACD/VOL/KDJ/RSI/WR）
   - 检查数值显示是否正确

3. **取消选中**

   - 点击空白区域取消选中
   - 检查指标数值是否显示第一条可见数据（不应该消失）

4. **滑动图表**

   - 左右滑动图表
   - 检查主图指标数值是否持续显示（显示第一条可见数据）
   - 确认不会出现指标数值消失的情况

5. **数值准确性**

   - 对比显示的数值与原始数据
   - 确保保留两位小数的格式正确

## 已完成的工作

- ✅ 创建主图指标数值显示 Widget
- ✅ 在主图视图中集成显示组件
- ✅ 确认所有副图指标都实现了数值显示
- ✅ 添加到导出文件
- ✅ 修复 linter 错误
- ✅ 修复滑动时指标数值消失的问题
- ✅ 修复指标文本位置跟随滚动移动的问题（dx 偏移）
- ✅ 实现默认显示第一条数据的功能（与 Swift 版本一致）
- ✅ 指标文本固定在屏幕左上角，不随滚动移动
- ✅ 更新文档

## 相关文件

### 新增文件

- `lib/kline/widgets/k_main_indicator_text_view.dart`
- `INDICATOR_VALUE_LABELS_IMPLEMENTATION.md`
- `FEATURE_COMPARISON.md`
- `BUGFIX_INDICATOR_VALUES_DISAPPEAR.md` - 修复滑动时指标消失
- `BUGFIX_INDICATOR_TEXT_POSITION.md` - 修复指标文本位置跟随滚动

### 修改文件

- `lib/kline/widgets/k_line_view.dart`
  - 添加 `_buildMainIndicatorTextLayer()` 方法
  - 在固定层显示指标文本（不随滚动移动）
  - 修复滑动时指标消失问题
- `lib/kline/widgets/chart/k_line_chart_view.dart`
  - 移除内部的指标文本显示
- `lib/kline/kline_export.dart`
  - 添加新组件导出

### 相关文件（参考）

- `lib/kline/widgets/renderers/macd_indicator_renderer.dart`
- `lib/kline/widgets/renderers/volume_indicator_renderer.dart`
- `lib/kline/widgets/renderers/kdj_indicator_renderer.dart`
- `lib/kline/widgets/renderers/rsi_indicator_renderer.dart`
- `lib/kline/widgets/renderers/wr_indicator_renderer.dart`
