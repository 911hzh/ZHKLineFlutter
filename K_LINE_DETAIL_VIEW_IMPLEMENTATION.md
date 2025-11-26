# K 线详情视图实现文档

## 概述

根据 Swift 版本的 `KLineDetailView.swift` 实现了 Flutter 版本的 K 线详情视图功能。

## Swift 版本参考

文件位置：`/Users/huang/Desktop/hzh/project/ZHKline/ZHKLine/Class/View/KLineDetailView.swift`

## Flutter 实现

### 1. 核心文件

- **k_line_detail_view.dart**: K 线详细信息显示组件
- **k_line_view.dart**: 集成详情视图的主视图

### 2. 功能特性

#### 2.1 显示内容

详情视图显示以下信息：

- 时间（新加坡时区格式：yyyy-MM-dd）
- 开盘价
- 最高价
- 最低价
- 收盘价
- 涨跌额（带颜色：涨绿跌红）
- 涨跌幅（带颜色：涨绿跌红）
- 成交量

#### 2.2 显示位置

- 固定在视图的左上角或右上角
- 智能判断：触摸点在屏幕左半部分时显示在右侧，右半部分时显示在左侧
- 与边缘保持 16px 的间距

#### 2.3 显示时机

- **长按手势**：长按 K 线时显示
- **点击手势**：单击 K 线时显示
- **保持显示**：长按结束后保持显示，直到滚动或其他操作
- **自动隐藏**：滚动时自动隐藏

#### 2.4 视觉效果

- 背景色：使用十字线颜色（透明度 0.9）
- 边框：1px 实线，使用十字线颜色
- 圆角：6px
- 动画：显示/隐藏时有 200ms 渐变动画
- 字体大小：8px
- 字体颜色：黑色（涨跌额和涨跌幅根据正负显示红/绿）

### 3. 实现细节

#### 3.1 KLineDetailView 组件

```dart
// 核心属性
final KLineModel data;           // 要显示的 K 线数据
final bool preferRight;          // 是否优先显示在右侧

// 布局结构
Container (背景 + 边框)
  └── Column (垂直布局)
      ├── 时间标签 (12px 高度)
      ├── 开盘价标签
      ├── 最高价标签
      ├── 最低价标签
      ├── 收盘价标签
      ├── 涨跌额标签 (带颜色)
      ├── 涨跌幅标签 (带颜色)
      └── 成交量标签
```

#### 3.2 在 KLineView 中的集成

```dart
// 状态管理
bool _shouldShowCrossLine = false;      // 是否显示十字线
KLineModel? _selectedKLineModel;        // 当前选中的 K 线数据
Offset _crossLinePoint = Offset.zero;   // 十字线位置

// 显示逻辑
if (_shouldShowCrossLine && _selectedKLineModel != null)
  _buildDetailView()

// 位置计算
- 根据触摸点位置（_crossLinePoint）判断显示在左侧还是右侧
- 使用 Positioned widget 定位
- 使用 AnimatedOpacity 实现渐变效果
```

### 4. 与 Swift 版本的对比

| 功能              | Swift 版本 | Flutter 版本 | 状态 |
| ----------------- | ---------- | ------------ | ---- |
| 显示 K 线详细信息 | ✅         | ✅           | 完成 |
| 智能定位（左/右） | ✅         | ✅           | 完成 |
| 新加坡时区格式化  | ✅         | ✅           | 完成 |
| 涨跌颜色显示      | ✅         | ✅           | 完成 |
| 显示/隐藏动画     | ✅         | ✅           | 完成 |
| 长按显示          | ✅         | ✅           | 完成 |
| 点击显示          | ✅         | ✅           | 完成 |
| 滚动时隐藏        | ✅         | ✅           | 完成 |
| 动态尺寸计算      | ✅         | ✅ (自动)    | 完成 |

### 5. 使用示例

```dart
// 在 Stack 中添加详情视图
if (_shouldShowCrossLine && _selectedKLineModel != null)
  Positioned(
    left: preferRight ? null : margin,
    right: preferRight ? margin : null,
    top: margin,
    child: IgnorePointer(
      child: AnimatedOpacity(
        opacity: _shouldShowCrossLine ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: KLineDetailView(
          data: _selectedKLineModel!,
          preferRight: preferRight,
        ),
      ),
    ),
  )
```

### 6. 注意事项

1. **时区处理**：使用 `intl` 包的 `DateFormat` 进行时间格式化，手动加 8 小时转换为新加坡时区
2. **数字格式化**：所有价格和成交量保留两位小数
3. **颜色规则**：涨跌额和涨跌幅使用系统颜色（涨绿跌红）
4. **手势处理**：使用 `IgnorePointer` 确保详情视图不干扰其他手势
5. **动画性能**：使用 `AnimatedOpacity` 而非手动动画控制，性能更好

### 7. 依赖项

- `intl: ^0.19.0`：用于日期格式化（已在 pubspec.yaml 中）

### 8. 未来优化建议

1. 可以考虑添加更多数据展示（如振幅、换手率等）
2. 可以支持自定义样式配置
3. 可以支持更多时区选择
4. 可以添加拖动功能，允许用户手动调整位置

## 完成状态

✅ 已完成 Flutter 版本的 K 线详情视图实现，功能与 Swift 版本保持一致。
