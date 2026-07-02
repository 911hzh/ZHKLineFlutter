# ZHKLine Flutter 架构图

外部业务侧主要关注数据、适配器、controller、指标定义、主题布局和可选 delegate；
package 内部负责滚动、缩放、可见区计算、绘制分层和默认 UI 组合。

```mermaid
flowchart TD
  page["业务页面"] --> data["List&lt;T&gt; 业务数据"]
  page --> adapter["KLineDataAdapter&lt;T&gt;<br/>DeepChartDataAdapter&lt;T&gt;"]
  page --> controller["KLineController<br/>缩放 / 滚动 / 选中 / 指标 id"]
  page --> spec["KLineIndicatorSpec&lt;T&gt;<br/>KLineIndicatorSeries&lt;T&gt;"]
  page --> config["Theme / Layout / Behavior"]
  page --> customDelegate["业务自定义 Delegate<br/>自定义绘制 / 自定义 UI"]
  page --> widget["KLineWidget&lt;T&gt;<br/>默认完整 K 线 UI"]
  page --> deep["DeepChart&lt;T&gt;<br/>盘口累计深度图"]

  data --> widget
  adapter --> widget
  controller --> widget
  spec --> widget
  config --> widget
  customDelegate --> delegate
  customDelegate --> deepDelegate

  widget --> chart["KLineChart&lt;T&gt;<br/>手势 / 滚动 / 缩放 / 可见区"]
  chart --> delegate["KLineChartDelegate&lt;T&gt;<br/>绘制协议"]
  delegate --> defaultImpl["KLineDefaultDelegateImpl&lt;T&gt;<br/>默认蜡烛 / 指标 / 覆盖层 / 详情"]
  defaultImpl --> util["内部默认工具<br/>坐标 / range / 标签 / 默认绘制"]
  chart --> fixedPainter["固定层 CustomPainter<br/>网格 / 坐标轴 / 十字线"]
  chart --> scrollPainter["SingleChildScrollView + 内容层 CustomPainter<br/>蜡烛 / 指标 / 副图"]
  delegate --> customLayers["可覆盖层<br/>网格 / 主图 / 副图 / Overlay / Selection"]

  deep --> deepDelegate["DeepChartDelegate&lt;T&gt;<br/>深度图布局 / 绘制 / 覆盖层"]
```

需要快速接入时，只看 `KLineWidget<T>`、`KLineDataAdapter<T>` 和
`KLineController`。需要自定义指标时，再看 `KLineIndicatorSpec<T>`。需要替换
绘制或 UI 时，传入业务自定义 delegate：想保留默认能力就继承
`KLineDefaultDelegateImpl<T>` 并调用 `super`，想完全接管绘制流程就实现
`KLineChartDelegate<T>` / `DeepChartDelegate<T>`。

[返回 README](../README.md)
