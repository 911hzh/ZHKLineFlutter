# 默认实现目录说明

`u_default_impl` 目录提供 package 内置的默认 K 线 UI 和默认绘制实现。它的目标是让用户在不自定义 `KLineChartDelegate` 的情况下，也能通过 `KLineWidget` 快速接入一套完整的 K 线图；如果用户需要更高自由度，也可以复用这里的 adapter、delegate、util 或 view 组件，只替换其中一部分。

## 调用关系

默认调用链如下：

```text
KLineWidget<T>
  -> KLineDefaultDelegateImpl<T>
    -> KLineDefaultDelegateImplUtil
      -> KLineDataAdapter<T>
      -> KLineDefaultIndicatorSelector / MainIndicatorLabels / SecondaryIndicatorLabels
```

核心原则：

- `KLineWidget` 负责默认 UI 装配。
- `KLineDefaultDelegateImpl` 负责承接 `KLineChartDelegate` 回调。
- `KLineDefaultDelegateImplUtil` 负责具体布局、绘制和 overlay 构建。
- `KLineDataAdapter` 负责把业务模型转换成默认实现需要的数据字段。
- `kline_views.dart` 负责默认 overlay 中可复用的 Widget。

## 文件职责

### `kline_widget.dart`

默认 K 线组件入口。

它封装了 `KLineChart`，并提供默认的 loading、empty、error、刷新提示和默认 delegate 组装逻辑。用户只需要传入：

- `dataSource`
- `adapter`
- 可选的 `controller`
- 可选的 `layout/theme/behavior`
- 可选的 `onScroll`

适合最简单的接入方式：

```dart
KLineWidget<MyCandle>(
  dataSource: candles,
  adapter: const MyCandleAdapter(),
)
```

如果用户传入自定义 `delegate`，`KLineWidget` 会使用用户的 delegate，从而绕过默认 delegate。

### `kline_data_adapter.dart`

业务数据适配层。

默认实现不要求用户的数据模型继承 package 的固定模型，而是通过 `KLineDataAdapter<T>` 读取业务字段。它负责提供：

- 开高低收量：`open/high/low/close/volume`
- 日期展示：`dateLabel`
- 指标数值：`indicatorValue`
- 主图指标标签：`mainIndicatorEntries`
- 副图指标标签：`secondaryIndicatorEntries`
- 详情面板字段：`detailEntries`

用户可以只实现基础 OHLCV 和日期；没有指标时返回 `null` 即可。需要自定义指标标题、周期或顺序时，可以覆盖 `mainIndicatorEntries` / `secondaryIndicatorEntries`。

### `kline_default_delegate.dart`

默认 delegate 承接层。

该文件定义：

- `KLineDefaultLayoutNode`
- `KLineDefaultDelegateImpl`
- `kLineDefaultSecondaryContentRect`
- `kLineDefaultDrawableClipRect`

`KLineDefaultDelegateImpl` 继承 `KLineChartDelegate`，但它不直接写绘制细节，只把 `chartHeight`、`getLayoutNodes`、`drawGrid`、`drawMainChart`、`drawSecondaryCharts`、`buildOverlayView`、`buildSelectionView` 等回调转发给 `KLineDefaultDelegateImplUtil`。

这样做的好处是：

- delegate 文件保持薄封装。
- 默认实现逻辑集中在 util。
- 用户可以跳过 delegate，直接复用 util 中的某个方法。

### `kline_default_delegate_util.dart`

默认实现的核心工具类。

`KLineDefaultDelegateImplUtil` 承载默认 K 线的具体静态实现，包括：

- 计算默认图表高度。
- 计算默认 layout nodes。
- 绘制固定网格层。
- 绘制主图蜡烛和主图指标。
- 绘制副图指标。
- 构建默认 overlay。
- 构建默认选中详情浮层。
- 计算主图/副图绘制区域。
- 计算价格和指标范围。
- 批量绘制蜡烛、柱状图和指标线。

如果用户想复用默认布局或默认绘制中的一部分，可以直接调用 util 静态方法：

```dart
final nodes = KLineDefaultDelegateImplUtil.getLayoutNodes(
  context,
  candles,
  adapter: const MyCandleAdapter(),
);
```

### `kline_views.dart`

默认 overlay Widget 集合。

该文件提供默认 UI 中可复用的 Widget：

- `KLineDefaultIndicatorSelector`
- `MainIndicatorLabels`
- `SecondaryIndicatorLabels`

它们只负责展示和交互，不负责数据计算。指标名称、数值和颜色索引都来自 `KLineDataAdapter` 和 `KLineChartContext`。

## 用户扩展方式

用户可以按需求选择不同接入层级：

### 1. 默认用法

只使用 `KLineWidget` 和 adapter。

```dart
KLineWidget<MyCandle>(
  dataSource: candles,
  adapter: const MyCandleAdapter(),
)
```

### 2. 自定义数据映射

覆盖 adapter 的指标和详情方法。

```dart
@override
List<KLineIndicatorEntry> mainIndicatorEntries(
  MyCandle item,
  KLineIndicatorSpec<MyCandle> indicator,
) {
  if (indicator.id == KLineDefaultIndicators.maId) {
    return [
      KLineIndicatorEntry(label: 'MA7', value: item.ma7, colorIndex: 0),
      KLineIndicatorEntry(label: 'MA25', value: item.ma25, colorIndex: 1),
    ];
  }
  return super.mainIndicatorEntries(item, indicator);
}
```

### 3. 复用默认 util

自定义 delegate，但复用默认实现中的部分逻辑。

```dart
class MyDelegate extends KLineChartDelegate<MyCandle> {
  const MyDelegate(this.adapter);

  final KLineDataAdapter<MyCandle> adapter;

  @override
  List<KLineLayoutNode<MyCandle>> getLayoutNodes(
    KLineChartContext<MyCandle> context,
    List<MyCandle> dataSource,
  ) {
    return KLineDefaultDelegateImplUtil.getLayoutNodes(
      context,
      dataSource,
      adapter: adapter,
    );
  }
}
```

### 4. 完全自定义

直接使用 `KLineChart<T>` 和自己的 `KLineChartDelegate<T>`，不依赖默认实现。

```dart
KLineChart<MyCandle>(
  dataSource: candles,
  delegate: const MyCustomDelegate(),
)
```

## 配置项说明

默认实现会读取 `KLineLayoutConfig` 中的配置，例如：

- `mainChartHeight`
- `secondaryPaneHeight`
- `indicatorSelectorHeight`
- `secondaryContentVerticalPadding`
- `gridHorizontalCount`
- `gridVerticalCount`
- `candleWidth`
- `candleSpacing`

其中 `secondaryContentVerticalPadding` 用于控制副图指标绘制内容区的上下留白，避免最大值或最小值贴住边框。
