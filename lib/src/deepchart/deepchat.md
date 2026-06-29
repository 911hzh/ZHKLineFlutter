# Deep Chart 设计说明

`deepchart` 提供一套独立于 K 线图的深度图实现，用左右两侧面积图展示买盘和卖盘的累计深度。

## 数据语义

深度图输入分为两侧：

- `bids`：买盘档位，通常按价格降序排列。
- `asks`：卖盘档位，通常按价格升序排列。
- 每个档位包含 `price` 和 `size`，对应行情接口中的 `[price, size]`。

默认实现会分别累计买盘和卖盘的 `size`，右侧数值轴展示累计数量刻度，底部数值轴展示价格刻度。

## 目录职责

- `adapter/`：定义 `DeepChartDataAdapter<T>`，让业务模型映射为价格和数量。
- `model/`：定义深度档位、累计节点和双边节点集合。
- `theme/`：定义默认颜色、线宽和布局配置。
- `delegate/`：定义深度图上下文、布局工具和可扩展绘制协议。
- `u_default_impl/`：默认 delegate，实现网格、面积图、坐标轴、图例和底部线条。
- `widgets/`：`DeepChart<T>` 组件入口，负责准备上下文并调度 delegate。

## 高度模型

`DeepChartLayoutConfig` 使用两段高度：

- `mainHeight`：中间图形区域高度。
- `bottomHeight`：底部价格数字行高度。

默认组件整体高度为 `mainHeight + bottomHeight`。业务方可以通过覆盖 `DeepChartDelegate.chartHeight` 自定义整体高度。

## 扩展方式

简单接入时，只需要提供：

```dart
DeepChart<MyDepthLevel>(
  bids: bids,
  asks: asks,
  adapter: const MyDepthAdapter(),
)
```

需要替换绘制时，可以继承 `DeepChartDelegate<T>` 或 `DeepChartDefaultDelegate<T>`：

- 覆盖 `getLayoutNodes` 自定义累计和坐标计算。
- 覆盖 `drawGrid` 自定义网格和轴文本。
- 覆盖 `drawChart` 自定义买卖盘曲线、面积或其他图层。
- 覆盖 `buildOverlayView` 添加图例、水印或业务按钮。
