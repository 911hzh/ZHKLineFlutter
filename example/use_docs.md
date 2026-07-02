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
  initialIndicators: const ['volume'],
)
```

## 指标与详情字段

默认 UI 会通过 adapter 读取指标和详情字段。业务侧可以覆盖这些方法：

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

  @override
  List<KLineDetailEntry> detailEntries(MyCandle item) {
    return [
      KLineDetailEntry(label: '开', value: item.open.toStringAsFixed(2)),
      KLineDetailEntry(label: '高', value: item.high.toStringAsFixed(2)),
      KLineDetailEntry(label: '低', value: item.low.toStringAsFixed(2)),
      KLineDetailEntry(label: '收', value: item.close.toStringAsFixed(2)),
    ];
  }
}
```

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

## 外部控制图表

`KLineController` 可以外部控制缩放、滚动、选中项和指标。

```dart
final controller = KLineController(initialIndicators: const ['volume']);

KLineWidget<MyCandle>(
  controller: controller,
  dataSource: candles,
  adapter: const MyCandleAdapter(),
)

controller.setScale(1.2);
controller.setScrollOffset(0);
controller.toggleIndicator(KLineDefaultIndicators.maId);
```

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
