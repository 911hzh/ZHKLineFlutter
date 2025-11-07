# Bug 修复：网格线随滚动移动问题

## 🐛 问题描述

在滑动 K 线图时，底部的交叉网格线（cross grid）会跟随内容一起移动，而不是保持固定。这与 Swift 原版的行为不一致。

## 🔍 问题原因

在原始的 Flutter 实现中，网格线（`CrossGridPainter`）被放在了可滚动的`SingleChildScrollView`内部的`KLineChartView`中，导致网格线随着内容一起滚动。

而在 Swift 版本中，网格线是固定在视图上的，不会随`UIScrollView`的内容偏移而移动。

## ✅ 解决方案

### 1. 调整视图层级结构

将网格线从可滚动内容中分离出来，使用`Stack`布局：

- **底层**：固定的网格线层（使用`Positioned.fill` + `IgnorePointer`）
- **上层**：可滚动的内容层（蜡烛图和技术指标）

### 2. 具体修改

#### `lib/kline/widgets/k_line_view.dart`

**修改前：**

```dart
SingleChildScrollView(
  child: KLineChartView(
    // 包含网格线和内容
  ),
)
```

**修改后：**

```dart
Stack(
  children: [
    // 固定的网格线层（不随滚动移动）
    _buildGridLayer(),

    // 可滚动的内容层
    SingleChildScrollView(
      child: KLineChartView(
        // 只包含蜡烛图和指标，不包含网格线
      ),
    ),
  ],
)
```

#### 新增方法 `_buildGridLayer()`

```dart
Widget _buildGridLayer() {
  return Positioned.fill(
    child: IgnorePointer(  // 不拦截手势事件
      child: Stack(
        children: [
          // 主图网格（固定位置）
          Positioned(...),

          // 副图网格（固定位置）
          if (hasSecondChart) Positioned(...),
        ],
      ),
    ),
  );
}
```

#### `lib/kline/widgets/chart/k_line_chart_view.dart`

移除了`KLineChartView`中的网格线绘制代码，因为网格线现在由外层的`KLineView`统一管理。

### 3. 关键技术点

1. **`IgnorePointer`**：确保固定的网格线层不会拦截手势事件，所有手势可以穿透到下层的可滚动内容。

2. **`Positioned.fill`**：让网格线层填满整个父容器，确保覆盖所有可视区域。

3. **分层绘制**：

   - 网格线在底层（固定）
   - 蜡烛图和指标在上层（可滚动）
   - 十字线在最上层（固定，但根据手势动态显示）

4. **数据同步**：网格线的标签文本（价格、日期）从`_showDatas`、`_maxPrice`、`_minPrice`获取，确保始终显示当前可见区域的正确数据。

## 📊 效果对比

### 修复前 ❌

- 滑动时，网格线随内容移动
- 网格线的位置会变化
- 不符合 Swift 版本行为

### 修复后 ✅

- 滑动时，网格线保持固定
- 只有蜡烛图和技术指标线在滚动
- 完全匹配 Swift 版本行为

## 🎯 与 Swift 版本的对应

### Swift 实现

```swift
class KLineView: UIView {
    private let scrollView = UIScrollView()  // 可滚动容器
    private let chartView: KLineChartView    // 图表内容

    // 网格线直接绘制在chartView的layer上
    // 而chartView的frame会随scrollView.contentOffset调整
    // 但网格线本身保持固定在可视区域
}
```

### Flutter 实现

```dart
class KLineView extends StatefulWidget {
  Stack(
    children: [
      _buildGridLayer(),           // 固定层
      SingleChildScrollView(       // 可滚动层
        child: KLineChartView(...),
      ),
    ],
  )
}
```

## 📝 相关文件

- `lib/kline/widgets/k_line_view.dart` - 主要修改
- `lib/kline/widgets/chart/k_line_chart_view.dart` - 移除网格线绘制
- `lib/kline/widgets/painters/k_line_base_painter.dart` - 网格线绘制器（被重用）

## ✅ 测试验证

1. ✅ 左右滑动 K 线图，网格线保持固定
2. ✅ 双指缩放，网格线保持固定，标签正确更新
3. ✅ 长按显示十字线，网格线保持固定
4. ✅ 切换技术指标，副图网格正确显示/隐藏
5. ✅ 价格和日期标签实时更新，显示当前可见区域的数据

## 🎉 结论

通过重构视图层级结构，成功实现了网格线固定的效果，完全匹配 Swift 原版的行为。这个修复提升了用户体验，使得滑动时更加清晰和专业。
