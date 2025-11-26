# K 线图手势处理实现文档

## 概述

本文档描述了 Flutter K 线图表的手势处理实现，严格参考 Swift 版本的 UIGestureRecognizer 实现逻辑。

## 手势类型

### 1. 缩放手势 (Pinch/Scale Gesture)

**对应 Swift**: `UIPinchGestureRecognizer`

**实现方式**: `GestureDetector` 的 `onScaleStart`, `onScaleUpdate`, `onScaleEnd`

**功能**: 双指捏合缩放，调整蜡烛图的宽度 (0.5x - 3.0x)

**关键代码**:

```dart
void _onScaleStart(ScaleStartDetails details) {
  _baseScale = KLineConfig.scale;
}

void _onScaleUpdate(ScaleUpdateDetails details) {
  // 只响应缩放手势（双指），不响应单指拖动
  if (details.scale != 1.0 && details.pointerCount >= 2) {
    setState(() {
      final newScale = (_baseScale * details.scale).clamp(0.5, 3.0);
      KLineConfig.scale = newScale;
      _updateDisplayData();
    });
  }
}
```

**注意事项**:

- 通过 `details.pointerCount >= 2` 确保只响应双指手势
- 通过 `details.scale != 1.0` 排除单指拖动
- 缩放范围限制在 0.5 到 3.0 倍之间

---

### 2. 滚动手势 (Pan/Scroll Gesture)

**对应 Swift**: `UIScrollView`

**实现方式**: `SingleChildScrollView` 的水平滚动

**功能**: 单指水平拖动，浏览历史 K 线数据

**关键代码**:

```dart
SingleChildScrollView(
  controller: _scrollController,
  scrollDirection: Axis.horizontal,
  physics: const ClampingScrollPhysics(),
  child: SizedBox(
    width: contentWidth,
    height: viewHeight,
    child: KLineChartView(...),
  ),
)
```

**注意事项**:

- 使用 `ClampingScrollPhysics` 提供更自然的滚动体验
- 通过 `ScrollController` 监听滚动偏移，实时更新显示数据

---

### 3. 长按手势 (Long Press Gesture)

**对应 Swift**: `UILongPressGestureRecognizer`

**实现方式**: `GestureDetector` 的 `onLongPressStart`, `onLongPressMoveUpdate`, `onLongPressEnd`

**功能**: 长按显示十字线，查看特定 K 线数据详情

**关键代码**:

```dart
void _onLongPressStart(LongPressStartDetails details) {
  _handleLongPress(details.localPosition);
}

void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
  _handleLongPress(details.localPosition);
}

void _onLongPressEnd(LongPressEndDetails details) {
  // 保持十字线显示，需要用户点击才能隐藏
}

void _handleLongPress(Offset localPosition) {
  if (_positionModels.isEmpty) return;

  // 1. 将触摸位置转换为绝对坐标
  final adjustedX = localPosition.dx + _scrollOffset;

  // 2. 查找最接近触摸点的蜡烛
  double minDistance = double.infinity;
  int selectedIndex = -1;

  for (int i = 0; i < _positionModels.length; i++) {
    final distance = (adjustedX - _positionModels[i].candleCenterX).abs();
    if (distance < minDistance) {
      minDistance = distance;
      selectedIndex = i;
    }
  }

  // 3. 更新十字线状态
  if (selectedIndex >= 0 && selectedIndex < _showDatas.length) {
    setState(() {
      _selectedKLineModel = _showDatas[selectedIndex];
      _shouldShowCrossLine = true;
      // 十字线X坐标对齐蜡烛中心，Y坐标跟随手指位置
      _crossLinePoint = Offset(
        _positionModels[selectedIndex].candleCenterX - _scrollOffset,
        localPosition.dy,
      );
    });
  }
}
```

**坐标转换逻辑**:

- **触摸坐标** (`localPosition.dx`): 相对于可见区域
- **绝对坐标** (`adjustedX`): 加上滚动偏移后的完整内容坐标
- **十字线坐标**: 需要转换回相对坐标进行绘制

**交互流程**:

1. **长按开始**: 显示十字线，对齐最近的 K 线
2. **移动手指**: 十字线跟随移动，自动吸附到最近的 K 线
3. **松开手指**: 十字线保持显示（不隐藏）

---

### 4. 点击手势 (Tap Gesture)

**对应 Swift**: `UITapGestureRecognizer`

**实现方式**: `GestureDetector` 的 `onTapDown`

**功能**: 单击隐藏十字线

**关键代码**:

```dart
void _onTapDown(TapDownDetails details) {
  if (_shouldShowCrossLine) {
    setState(() {
      _shouldShowCrossLine = false;
      _selectedKLineModel = null;
    });
  }
}
```

---

## 手势层级架构

为了避免手势冲突，采用了统一的手势处理策略：

```dart
Stack(
  children: [
    // 第1层：固定的网格线（不响应手势）
    _buildGridLayer(),

    // 第2层：统一的手势处理层（所有手势在一个 GestureDetector 中）
    GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      onTapDown: _onTapDown,
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      child: SingleChildScrollView(...),
    ),

    // 第3层：底部控制面板
    Positioned(bottom: 0, child: KTechnicalIndicatorControlView(...)),
  ],
)
```

### 层级设计原理

1. **第 1 层（网格线）**: 使用 `IgnorePointer`，完全不响应手势
2. **第 2 层（统一手势层）**: 所有手势在一个 `GestureDetector` 中处理，避免手势冲突
   - 缩放手势：通过 `(details.scale - 1.0).abs() > 0.01` 判断，只响应真正的缩放
   - 滚动手势：由 `SingleChildScrollView` 自动处理单指拖动
   - 长按/点击：Flutter 自动协调优先级
3. **第 3 层（控制面板）**: 独立的交互层，不影响图表手势

### 手势优先级

- **长按** > **点击** > **滚动** > **缩放**
- 单指拖动 → 滚动（scale = 1.0，由 SingleChildScrollView 处理）
- 双指捏合 → 缩放（scale ≠ 1.0，由 onScaleUpdate 处理）
- 长按时 → 显示十字线（Flutter 自动暂停滚动）
- 点击时 → 隐藏十字线（只在已显示十字线时响应）

---

## 与 Swift 版本的对应关系

| Swift 手势识别器               | Flutter 实现方式                | 功能说明       |
| ------------------------------ | ------------------------------- | -------------- |
| `UIPinchGestureRecognizer`     | `GestureDetector.onScaleUpdate` | 双指缩放       |
| `UIScrollView`                 | `SingleChildScrollView`         | 水平滚动       |
| `UILongPressGestureRecognizer` | `GestureDetector.onLongPress*`  | 长按显示十字线 |
| `UITapGestureRecognizer`       | `GestureDetector.onTapDown`     | 点击隐藏十字线 |

---

## 关键改进点

### 1. 解决手势冲突 ⚠️

**问题 1**: 最初尝试将手势分层（缩放层 + 长按/点击覆盖层），导致覆盖层阻止了底层的滚动

**问题 2**: 缩放手势 `onScaleUpdate` 和滚动手势 `SingleChildScrollView` 相互干扰

**最终解决方案** ✅:

1. **统一手势处理**: 将所有手势放在同一个 `GestureDetector` 中，让 Flutter 自动协调
2. **精确的缩放判断**: 通过 `(details.scale - 1.0).abs() > 0.01` 判断是否是真正的缩放手势
   - 单指拖动时 `scale` 始终为 `1.0`，不触发缩放逻辑
   - 双指缩放时 `scale` 发生变化，触发缩放逻辑
   - 设置阈值 `0.01` 避免微小抖动触发缩放
3. **移除覆盖层**: 不使用独立的手势层覆盖，避免阻止滚动

### 2. 精确的坐标转换

**问题**: 长按时十字线位置不准确

**解决方案**:

- 触摸坐标 + 滚动偏移 = 绝对坐标（用于查找 K 线）
- 绝对坐标 - 滚动偏移 = 相对坐标（用于绘制十字线）

### 3. 优化用户体验

- 长按松开后十字线保持显示（符合交易软件习惯）
- 点击空白区域隐藏十字线
- 十字线自动吸附到最近的 K 线中心
- 添加调试日志，方便排查手势问题

---

## 测试建议

### 基础手势测试

1. ✅ 单指左右拖动，验证滚动是否流畅
2. ✅ 双指捏合缩放，验证蜡烛宽度是否变化
3. ✅ 长按图表，验证十字线是否显示并对齐 K 线
4. ✅ 长按移动手指，验证十字线是否跟随
5. ✅ 松开长按，验证十字线是否保持显示
6. ✅ 点击空白区域，验证十字线是否隐藏

### 组合手势测试

1. ✅ 滚动时长按，验证能否正常显示十字线
2. ✅ 长按时移动到边缘，验证滚动是否正常
3. ✅ 缩放后长按，验证十字线位置是否准确
4. ✅ 快速滑动后立即长按，验证响应是否及时

### 边界情况测试

1. ✅ 在最左侧长按
2. ✅ 在最右侧长按
3. ✅ 数据很少时（< 10 根 K 线）的手势
4. ✅ 数据很多时（> 2000 根 K 线）的性能

---

## 后续优化方向

1. **详情浮窗**: 长按时显示 K 线详细信息（开高低收、成交量等）
2. **震动反馈**: 长按时添加轻微震动（HapticFeedback）
3. **缩放中心点**: 以双指中心点为基准缩放（目前是以左侧为基准）
4. **边界回弹**: 滚动到边界时的弹性效果
5. **手势动画**: 添加十字线显示/隐藏的平滑过渡动画

---

## 总结

本实现严格参考了 Swift 版本的手势处理逻辑，通过合理的层级设计和手势优先级控制，实现了流畅、自然的交互体验。核心思想是：

1. **分层设计**: 不同手势分配到不同的层级，避免冲突
2. **精确判断**: 通过手指数量和缩放比例区分手势类型
3. **坐标转换**: 正确处理触摸坐标、绝对坐标、相对坐标之间的转换
4. **用户体验**: 符合交易软件的使用习惯，十字线保持显示直到用户主动隐藏

参考 Swift 版本实现，Flutter 版本达到了相同的功能和体验标准。
