# 坐标系统修复说明

## 🎯 核心问题

滑动后可见区域没有完全绘制图表的原因是坐标计算不正确。

## 📐 坐标系统对比

### Swift 版本的坐标系统

```swift
// 在 KLineView.swift 中
scrollView.addSubview(chartView)
chartView.frame.origin.x = scrollView.contentOffset.x  // ⚠️ 关键！

// 在 KLineCrandleIndexUtil.swift 中
let centerX = itemX - offset + KLineConfig.shared.crandleInsets.left + candleWidth/2
```

**工作原理**：

1. `chartView` 的 frame 会随着滚动而移动
2. `chartView` 内部的坐标是**相对于 chartView 自身**的
3. 所以需要 `itemX - offset` 来计算相对坐标

### Flutter 版本的坐标系统（修复前）

```dart
// 在 k_line_view.dart 中
SingleChildScrollView(
  child: SizedBox(
    width: contentWidth,  // 内容总宽度
    child: KLineChartView(...),
  ),
)

// 在 k_line_crandle_index_util.dart 中（错误）
final centerX = itemX - offset + config.crandleInsets.left + config.candleWidth / 2;
```

**问题**：

1. `SingleChildScrollView` 的内容**不会移动**，而是 viewport 在移动
2. 内容的坐标应该是**绝对坐标**，不是相对坐标
3. 所以不应该 `itemX - offset`

### Flutter 版本的坐标系统（修复后）✅

```dart
// 在 k_line_crandle_index_util.dart 中（正确）
final centerX = itemX + config.crandleInsets.left + config.candleWidth / 2;
```

**正确原理**：

1. `SingleChildScrollView` 自动处理滚动偏移
2. 内容的坐标是**绝对坐标**（相对于整个内容宽度）
3. Flutter 会自动裁剪和显示可见区域

## 🔧 修复详情

### 1. 位置计算修复

**文件**：`lib/kline/utils/k_line_crandle_index_util.dart`

**修改前**：

```dart
final centerX = itemX - offset + config.crandleInsets.left + config.candleWidth / 2;
```

**修改后**：

```dart
// 注意：Flutter的SingleChildScrollView会自动处理滚动偏移，所以这里不需要减去offset
// Swift版本需要减offset是因为chartView.frame.origin.x被设置为offset
final centerX = itemX + config.crandleInsets.left + config.candleWidth / 2;
```

### 2. 十字线位置计算（保持不变）

**文件**：`lib/kline/widgets/k_line_view.dart`

```dart
void _handleLongPress(Offset localPosition) {
  // 1. localPosition.dx 是相对于可见区域的坐标
  // 2. 加上 _scrollOffset 得到绝对坐标
  final adjustedX = localPosition.dx + _scrollOffset;

  // 3. 在 positionModels 中查找（candleCenterX 是绝对坐标）
  for (int i = 0; i < _positionModels.length; i++) {
    final distance = (adjustedX - _positionModels[i].candleCenterX).abs();
    // ...
  }

  // 4. 设置十字线位置（需要转换回相对坐标）
  _crossLinePoint = Offset(
    _positionModels[selectedIndex].candleCenterX - _scrollOffset,  // 绝对 -> 相对
    localPosition.dy,
  );
}
```

## 📊 坐标转换关系

| 坐标类型     | 说明                 | 计算方法                  | 用途                       |
| ------------ | -------------------- | ------------------------- | -------------------------- |
| **绝对坐标** | 相对于整个内容的坐标 | `itemX + insets.left`     | 存储在 `positionModels` 中 |
| **相对坐标** | 相对于可见区域的坐标 | `绝对坐标 - scrollOffset` | 用于绘制和十字线显示       |
| **触摸坐标** | 手势触摸位置         | `localPosition.dx`        | 是相对坐标                 |

### 转换公式

```dart
// 相对坐标 -> 绝对坐标
absoluteX = relativeX + scrollOffset

// 绝对坐标 -> 相对坐标
relativeX = absoluteX - scrollOffset
```

## 🎨 绘制流程

### 1. 计算阶段（computerSize）

```dart
// 输入：datas, drawMaxWidth, offset, ...
// 输出：positionModels（包含绝对坐标）

for (int i = indexBegin; i <= indexEnd; i++) {
  final itemX = i * (candleSpace + candleWidth);
  final centerX = itemX + insets.left + candleWidth / 2;  // ✅ 绝对坐标

  // 存储绝对坐标
  positionModel.candleCenterX = centerX;
}
```

### 2. 绘制阶段（CustomPainter）

```dart
// Flutter 会自动：
// 1. 根据 ScrollPosition 移动 viewport
// 2. 裁剪不可见的内容
// 3. 只绘制可见区域

// 我们只需要使用绝对坐标绘制即可
canvas.drawRect(
  Rect.fromCenter(
    center: Offset(model.candleCenterX, y),  // ✅ 使用绝对坐标
    width: candleWidth,
    height: height,
  ),
);
```

### 3. 交互阶段（手势处理）

```dart
// 触摸位置是相对坐标，需要转换为绝对坐标查找
final adjustedX = localPosition.dx + _scrollOffset;  // 相对 -> 绝对

// 查找对应的蜡烛（比较绝对坐标）
final distance = (adjustedX - model.candleCenterX).abs();

// 十字线位置需要转换回相对坐标
_crossLinePoint = Offset(
  model.candleCenterX - _scrollOffset,  // 绝对 -> 相对
  localPosition.dy,
);
```

## ⚠️ 常见陷阱

### ❌ 错误 1：混用绝对和相对坐标

```dart
// 错误：adjustedX 是绝对坐标，但直接用于绘制
canvas.drawLine(Offset(adjustedX, 0), Offset(adjustedX, height));
```

### ❌ 错误 2：重复减去 offset

```dart
// 错误：centerX 已经是绝对坐标，不应该再减
final centerX = itemX - offset + insets.left;  // ❌
```

### ❌ 错误 3：忘记坐标转换

```dart
// 错误：十字线位置应该是相对坐标
_crossLinePoint = Offset(model.candleCenterX, y);  // ❌ 应该减去 scrollOffset
```

## ✅ 正确做法总结

1. **存储位置时**：使用绝对坐标（不减 offset）
2. **绘制时**：直接使用绝对坐标（Flutter 自动处理滚动）
3. **处理触摸时**：
   - 触摸坐标 + scrollOffset = 绝对坐标（用于查找）
   - 绝对坐标 - scrollOffset = 相对坐标（用于显示）

## 🧪 验证方法

### 测试 1：滑动查看所有数据

```
✅ 预期：滑动到任何位置，可见区域都完整绘制蜡烛图
❌ 错误：某些位置出现空白或蜡烛图不完整
```

### 测试 2：十字线位置

```
✅ 预期：长按任何蜡烛，十字线精确对准蜡烛中心
❌ 错误：十字线位置偏移或错位
```

### 测试 3：技术指标线

```
✅ 预期：MA/EMA/BOLL 线条连续，没有断裂
❌ 错误：指标线在滚动后出现断裂或错位
```

### 测试 4：网格线

```
✅ 预期：滚动时网格线保持固定，不随内容移动
❌ 错误：网格线跟随内容滚动
```

## 📝 相关文件

- `lib/kline/utils/k_line_crandle_index_util.dart` - 位置计算
- `lib/kline/widgets/k_line_view.dart` - 滚动和手势处理
- `lib/kline/widgets/painters/k_line_base_painter.dart` - 绘制逻辑
- `lib/kline/widgets/chart/k_line_chart_view.dart` - 图表视图

## 🎉 修复效果

修复后，Flutter 版本的坐标系统与 Swift 版本在逻辑上等价，但实现方式更符合 Flutter 的 widget 体系：

- ✅ 滑动流畅，所有位置都正确绘制
- ✅ 十字线位置精确
- ✅ 网格线保持固定
- ✅ 技术指标线连续完整
- ✅ 性能优化（Flutter 自动裁剪不可见内容）
