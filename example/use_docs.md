# ZHKLine Flutter 使用文档

本文档记录 example 中的具体接入方式、自定义 UI 示例和深度图用法。根目录 `README.md` 只保留快速介绍和最小接入。

## 运行 Example

```bash
cd example
flutter pub get
flutter run -d macos
```

example 中的行情数据来自火币 REST API：

- K 线：`/market/history/kline`
- 深度图：`/market/depth`

相关页面入口：

- K 线默认示例：`lib/module/usecase/pages/kline/KLineDemoPage.dart`
- 深度图示例：`lib/module/usecase/pages/deep_chart/DeepChartDemoPage.dart`
- 自定义 K 线示例：`lib/module/usecase/pages/custom_page/`

## K 线快速接入

推荐导入公共入口：

```dart
import 'package:kline_flutter/kline_flutter.dart';
```

业务模型不需要继承 package 类型，只需要提供 adapter：

```dart
class MyCandle {
  const MyCandle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timeLabel,
  });

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String timeLabel;
}

class MyCandleAdapter extends KLineDataAdapter<MyCandle> {
  const MyCandleAdapter();

  @override
  double open(MyCandle item) => item.open;

  @override
  double high(MyCandle item) => item.high;

  @override
  double low(MyCandle item) => item.low;

  @override
  double close(MyCandle item) => item.close;

  @override
  double volume(MyCandle item) => item.volume;

  @override
  String dateLabel(MyCandle item) => item.timeLabel;
}
```

然后使用默认 UI：

```dart
KLineWidget<MyCandle>(
  dataSource: candles,
  adapter: const MyCandleAdapter(),
  initialIndicators: const [KLineDefaultIndicators.volumeId],
)
```

完整 demo 可看 `example/lib/module/usecase/pages/kline/KLineDemoPage.dart`。

## 指标与详情字段

默认 UI 会通过 adapter 读取指标和详情字段。业务侧可以覆盖这些方法：
下面只展示覆盖方法，假设业务模型已经包含 `ma5`、`ma30`、`cci14` 等指标字段。

```dart
class MyCandleAdapter extends KLineDataAdapter<MyCandle> {
  const MyCandleAdapter();

  @override
  double open(MyCandle item) => item.open;

  @override
  double high(MyCandle item) => item.high;

  @override
  double low(MyCandle item) => item.low;

  @override
  double close(MyCandle item) => item.close;

  @override
  double volume(MyCandle item) => item.volume;

  @override
  String dateLabel(MyCandle item) => item.timeLabel;

  @override
  double? indicatorValue(MyCandle item, String valueId) {
    return switch (valueId) {
      KLineDefaultIndicators.ma5 => item.ma5,
      KLineDefaultIndicators.ma30 => item.ma30,
      'cci14' => item.cci14,
      _ => null,
    };
  }

  @override
  List<KLineIndicatorEntry> mainIndicatorEntries(
    MyCandle item,
    KLineIndicatorSpec<MyCandle> indicator,
  ) {
    if (indicator.id == KLineDefaultIndicators.maId) {
      return [
        KLineIndicatorEntry(label: 'MA5', value: item.ma5, colorIndex: 0),
        KLineIndicatorEntry(label: 'MA30', value: item.ma30, colorIndex: 1),
      ];
    }
    return super.mainIndicatorEntries(item, indicator);
  }

  @override
  List<KLineDetailEntry> detailEntries(MyCandle item) {
    return [
      KLineDetailEntry('开', item.open.toStringAsFixed(2)),
      KLineDetailEntry('高', item.high.toStringAsFixed(2)),
      KLineDetailEntry('低', item.low.toStringAsFixed(2)),
      KLineDetailEntry('收', item.close.toStringAsFixed(2)),
    ];
  }
}
```

完整 demo 可看 `example/lib/module/usecase/pages/custom_page/custom_indicator_entries_page.dart`。

## 动态指标列表

`KLineWidget` 的默认选择器来自 `mainIndicators` 和 `secondaryIndicators`：

- `null`：使用 package 默认指标，主图为 MA/EMA/BOLL，副图为 VOL/MACD/KDJ/RSI/WR。
- `[]`：不展示对应主图或副图指标。
- 自定义列表：只展示传入的指标。需要默认 + 自定义时，显式组合列表。

普通 series 指标不需要自己写绘制逻辑，默认 delegate 会自动绘制折线、计算范围和展示标签：

```dart
KLineWidget<MyCandle>(
  dataSource: candles,
  adapter: const MyCandleAdapter(),
  initialIndicators: const [KLineDefaultIndicators.volumeId, 'cci'],
  secondaryIndicators: [
    KLineDefaultIndicators.volume<MyCandle>(),
    const KLineIndicatorSpec<MyCandle>(
      id: 'cci',
      label: 'CCI',
      series: [
        KLineIndicatorSeries<MyCandle>(
          id: 'cci14',
          label: 'CCI14',
          colorIndex: 2,
        ),
      ],
    ),
  ],
)
```

`KLineIndicatorSeries.id` 会作为 `valueId` 传给 `adapter.indicatorValue(item, valueId)`。如果某个指标值不想经过 adapter，也可以直接传 `value` 回调：

```dart
const KLineIndicatorSeries<MyCandle>(
  id: 'bodyPower',
  label: 'BODY',
  colorIndex: 0,
  value: _bodyPowerValue,
)
```

需要柱状图、混合图或特殊绘制时，在 `KLineIndicatorSpec.renderer` 里接管绘制：

```dart
void drawBodyPower(
  Canvas canvas,
  Rect rect,
  KLineChartContext<MyCandle> context,
  KLineDataAdapter<MyCandle> adapter,
  KLineIndicatorSpec<MyCandle> indicator,
) {
  // 根据 context.layoutNodes 和 series.valueOf(item, adapter) 自定义绘制。
}

const KLineIndicatorSpec<MyCandle>(
  id: 'bodyPower',
  label: '强弱',
  height: 76,
  renderer: drawBodyPower,
  series: [
    KLineIndicatorSeries<MyCandle>(
      id: 'bodyPower',
      label: 'BODY',
      colorIndex: 0,
      value: _bodyPowerValue,
    ),
  ],
)
```

完整 demo 可看 `example/lib/module/usecase/pages/custom_page/custom_indicator_spec_page.dart`。

## 自定义主题和布局

```dart
KLineWidget<MyCandle>(
  dataSource: candles,
  adapter: const MyCandleAdapter(),
  theme: const KLineTheme(
    candleUpColor: Color(0xFFF14965),
    candleDownColor: Color(0xFF00B066),
    gridLineColor: Color(0xFFE2E8F0),
  ),
  layout: const KLineLayoutConfig(
    candleWidth: 8,
    candleSpacing: 2,
    mainChartHeight: 360,
  ),
  behavior: const KLineBehaviorConfig(
    enableScale: true,
    enableCrosshair: true,
  ),
)
```

完整 demo 可看 `example/lib/module/usecase/pages/custom_page/custom_theme_layout_page.dart`。

## 自定义绘制

复杂业务可以传入自己的 delegate。delegate 可以接管网格、主图、副图、覆盖层和选中详情。

```dart
class OrderLineDelegate extends KLineDefaultDelegateImpl<MyCandle> {
  const OrderLineDelegate({required super.adapter});

  @override
  void drawMainChart(Canvas canvas, Size size, KLineChartContext<MyCandle> context) {
    super.drawMainChart(canvas, size, context);

    final y = context.layout.contentPadding.top + context.layout.contentHeightForMainChart() * 0.62;
    final paint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 1.4;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
}

KLineWidget<MyCandle>(
  dataSource: candles,
  adapter: const MyCandleAdapter(),
  delegate: const OrderLineDelegate(adapter: MyCandleAdapter()),
)
```

完整 demo 可看 `example/lib/module/usecase/pages/custom_page/custom_main_chart_page.dart`。

## 自定义网格、主图和副图

如果只是想在默认 K 线图上追加业务元素，优先继承 `KLineDefaultDelegateImpl`，
然后覆盖对应绘制方法，并在方法里先调用 `super` 保留默认 K 线、指标和网格。

```dart
class MyGridDelegate extends KLineDefaultDelegateImpl<MyCandle> {
  const MyGridDelegate({required super.adapter});

  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<MyCandle> context) {
    super.drawGrid(canvas, size, context);
    // 追加不会随横向滚动移动的预警线、水印、坐标轴标识。
  }
}

class MyMainChartDelegate extends KLineDefaultDelegateImpl<MyCandle> {
  const MyMainChartDelegate({required super.adapter});

  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<MyCandle> context,
  ) {
    super.drawMainChart(canvas, size, context);
    // 追加委托价、成本线、买卖点、策略信号。
  }
}

class MySecondaryChartDelegate extends KLineDefaultDelegateImpl<MyCandle> {
  const MySecondaryChartDelegate({required super.adapter});

  @override
  void drawSecondaryCharts(
    Canvas canvas,
    Size size,
    KLineChartContext<MyCandle> context,
  ) {
    super.drawSecondaryCharts(canvas, size, context);
    // 追加副图风险区间、阈值线、说明标签。
  }
}
```

完整 demo 可看：

- `example/lib/module/usecase/pages/custom_page/custom_grid_page.dart`：自定义固定网格层。
- `example/lib/module/usecase/pages/custom_page/custom_main_chart_page.dart`：自定义主图绘制。
- `example/lib/module/usecase/pages/custom_page/custom_secondary_chart_page.dart`：自定义副图绘制。

## 自定义覆盖层 UI

覆盖层是 Flutter widget 层，适合替换默认指标文案、底部指标选择器，或叠加
顶部行情条、浮动按钮、可见区间提示等 UI。

```dart
class MyOverlayDelegate extends KLineDefaultDelegateImpl<MyCandle> {
  const MyOverlayDelegate({required super.adapter});

  @override
  double chartHeight(KLineChartContext<MyCandle> context) {
    return super.chartHeight(context) + 50;
  }

  @override
  Widget? buildOverlayView(
    BuildContext context,
    KLineChartContext<MyCandle> chartContext,
  ) {
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 10,
          child: Text('visible ${chartContext.visibleRange.start}'),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 6,
          child: TextButton(
            onPressed: () {
              chartContext.controller.toggleIndicator(
                KLineDefaultIndicators.maId,
              );
            },
            child: const Text('切换 MA'),
          ),
        ),
      ],
    );
  }
}
```

如果覆盖 `buildOverlayView` 后仍然需要指标切换能力，需要自己在 overlay 中调用
`chartContext.controller.toggleIndicator(indicator.id)`。完整 demo 可看
`example/lib/module/usecase/pages/custom_page/custom_overlay_page.dart`。

## 自定义长按详情 UI

长按选中后，默认详情面板来自 `buildSelectionView`。业务侧可以用
`selectedNode.item` 读取当前 K 线数据，并根据触摸位置决定面板展示在左侧还是右侧。

```dart
class MySelectionDelegate extends KLineDefaultDelegateImpl<MyCandle> {
  const MySelectionDelegate({required super.adapter});

  @override
  Widget? buildSelectionView(
    BuildContext context,
    KLineChartContext<MyCandle> chartContext,
    KLineLayoutNode<MyCandle> selectedNode,
  ) {
    final touchX = chartContext.controller.selectionLocalPosition?.dx ?? 0;
    final showRight = touchX < chartContext.viewportSize.width / 2;
    return Positioned(
      left: showRight ? null : 12,
      right: showRight ? 12 : null,
      top: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('close: ${adapter.close(selectedNode.item)}'),
        ),
      ),
    );
  }
}
```

完整 demo 可看
`example/lib/module/usecase/pages/custom_page/custom_selection_view_page.dart`。

## 完全自定义核心图表

如果默认 K 线的绘制协议也不够用，可以直接使用 `KLineChart` 和
`KLineChartDelegate`。这种方式会跳过默认 UI，需要自己定义图表高度、网格、
主图绘制、选中浮层和滚动回调。

```dart
class MyCoreDelegate extends KLineChartDelegate<MyCandle> {
  const MyCoreDelegate({required this.adapter, required this.onScroll});

  final KLineDataAdapter<MyCandle> adapter;
  final void Function(KLineChartContext<MyCandle>, KLineScrollMetrics) onScroll;

  @override
  double chartHeight(KLineChartContext<MyCandle> context) {
    return context.layout.mainChartHeight;
  }

  @override
  void drawGrid(Canvas canvas, Size size, KLineChartContext<MyCandle> context) {
    // 自己绘制网格、坐标和标题。
  }

  @override
  void drawMainChart(
    Canvas canvas,
    Size size,
    KLineChartContext<MyCandle> context,
  ) {
    // 根据 context.layoutNodes 自己绘制分时线、面积图或特殊金融图表。
  }

  @override
  void didScroll(
    KLineChartContext<MyCandle> context,
    KLineScrollMetrics metrics,
  ) {
    onScroll(context, metrics);
  }
}

KLineChart<MyCandle>(
  controller: controller,
  dataSource: candles,
  delegate: MyCoreDelegate(adapter: adapter, onScroll: onScroll),
)
```

完整 demo 可看
`example/lib/module/usecase/pages/custom_page/custom_core_chart_page.dart`。

## 外部控制图表

`KLineController` 可以外部控制缩放、滚动、选中项和指标。

```dart
final controller = KLineController(
  initialIndicators: const [KLineDefaultIndicators.volumeId],
);

KLineWidget<MyCandle>(
  controller: controller,
  dataSource: candles,
  adapter: const MyCandleAdapter(),
)

controller.setScale(1.2);
controller.setScrollOffset(0);
controller.toggleIndicator(KLineDefaultIndicators.maId);
```

完整 demo 可看 `example/lib/module/usecase/pages/custom_page/custom_controller_page.dart`。

## 实时数据接入

实时场景不要把插入位置判断放进 package。业务层收到 socket 或分页结果后，先更新 `dataSource`，再用 `KLineController` 发起一次滚动请求。

```dart
final controller = KLineController(initialFollowLatest: true);
var candles = <MyCandle>[];

void onSocketCandle(MyCandle latest) {
  setState(() {
    candles = [latest, ...candles];
  });

  if (controller.isFollowingLatest) {
    controller.scrollToLatest();
  }
}

void onLoadOlder(List<MyCandle> olderCandles) {
  setState(() {
    candles = [...candles, ...olderCandles];
  });

  controller.scrollToIndex(
    candles.length - 1,
    alignment: KLineScrollAlignment.right,
  );
}

KLineWidget<MyCandle>(
  controller: controller,
  dataSource: candles,
  adapter: const MyCandleAdapter(),
)
```

如果只想切换“是否跟随最新”，调用 `controller.setFollowingLatest(true/false)`；如果需要立刻回到最新，调用 `controller.scrollToLatest()`。完整 demo 可看 `example/lib/module/usecase/pages/custom_page/custom_live_update_page.dart`，其中 timer 只在开启跟随最新时模拟推送，加载更多和整窗替换都由页面先改数据再发滚动请求。

## Loading / Empty / Error

```dart
KLineWidget<MyCandle>(
  dataSource: candles,
  adapter: const MyCandleAdapter(),
  isLoading: isLoading,
  error: error,
  onRetry: retry,
  loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
  emptyBuilder: (_) => const Center(child: Text('暂无数据')),
  errorBuilder: (_, error, retry) {
    return Center(
      child: ElevatedButton(
        onPressed: retry,
        child: Text('重新加载: $error'),
      ),
    );
  },
)
```

完整 demo 可看 `example/lib/module/usecase/pages/custom_page/custom_state_builder_page.dart`。

## 深度图接入

深度图输入为买盘和卖盘，两侧数据都通过 adapter 映射为 `price` 和 `size`。

```dart
class MyDepthLevel {
  const MyDepthLevel({required this.price, required this.size});

  final double price;
  final double size;
}

class MyDepthAdapter extends DeepChartDataAdapter<MyDepthLevel> {
  const MyDepthAdapter();

  @override
  double price(MyDepthLevel item) => item.price;

  @override
  double size(MyDepthLevel item) => item.size;
}

DeepChart<MyDepthLevel>(
  bids: bids,
  asks: asks,
  adapter: const MyDepthAdapter(),
)
```

默认深度图会分别累计买盘和卖盘数量：

- 右侧坐标轴：累计数量刻度。
- 底部坐标轴：价格刻度。
- 买盘：从中线向左展开。
- 卖盘：从中线向右展开。

完整 demo 可看 `example/lib/module/usecase/pages/deep_chart/DeepChartDemoPage.dart`。

## 自定义深度图

```dart
class MyDepthDelegate extends DeepChartDefaultDelegate<MyDepthLevel> {
  const MyDepthDelegate();

  @override
  void drawGrid(Canvas canvas, Size size, DeepChartContext<MyDepthLevel> context) {
    super.drawGrid(canvas, size, context);
    // 追加业务网格、价格提示或水印。
  }
}

DeepChart<MyDepthLevel>(
  bids: bids,
  asks: asks,
  adapter: const MyDepthAdapter(),
  delegate: const MyDepthDelegate(),
  layout: const DeepChartLayoutConfig(
    mainHeight: 200,
    bottomHeight: 20,
  ),
)
```

深度图默认接入完整 demo 可看 `example/lib/module/usecase/pages/deep_chart/DeepChartDemoPage.dart`；
自定义 delegate 可在本节示例基础上继承 `DeepChartDefaultDelegate`。

## Example 自定义页面结构

`custom_page` 目录中的示例统一复用 `CustomKLineDemoShell`：

- `delegateBuilder`：复用默认数据加载，只替换绘制 delegate。
- `controlsBuilder`：复用同一个 `KLineController`，展示外部控制能力。
- `chartBuilder`：完全替换图表区域，适合自定义 loading/error/empty UI。
- `CustomKLineDemoActions`：shell 显式传入 `retry` / `loadMore`，自定义页面不依赖 `BuildContext` 读取 Cubit。

## 测试

常用验证命令：

```bash
# package 测试
flutter test
flutter analyze

# example 测试
cd example
flutter test
flutter analyze
```
