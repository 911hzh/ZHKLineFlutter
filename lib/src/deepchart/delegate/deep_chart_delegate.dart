import 'package:flutter/material.dart';

import '../adapter/deep_chart_data_adapter.dart';
import '../model/deep_depth_entry.dart';
import '../theme/deep_chart_theme.dart';

/// 深度图线段布局结果。
///
/// 默认实现用它描述网格线、底部分隔线等两点线段。
class DeepChartGridLine {
  /// 创建线段布局结果。
  const DeepChartGridLine({required this.start, required this.end});

  /// 线段起点。
  final Offset start;

  /// 线段终点。
  final Offset end;
}

/// 深度图文本布局结果。
///
/// 默认实现用它描述底部价格标签所在区域和横向对齐方式。
class DeepChartTextLayout {
  /// 创建文本布局结果。
  const DeepChartTextLayout({required this.rect, required this.textAlign});

  /// 文本所在矩形区域。
  final Rect rect;

  /// 文本在 [rect] 内的横向对齐方式。
  final TextAlign textAlign;
}

/// 深度图布局、绘制和覆盖层构建时传递给 delegate 的上下文。
class DeepChartContext<T> {
  /// 创建深度图上下文。
  const DeepChartContext({
    required this.bids,
    required this.asks,
    required this.adapter,
    required this.theme,
    required this.layout,
    required this.viewportSize,
    required this.nodes,
  });

  /// 买盘原始数据。
  final List<T> bids;

  /// 卖盘原始数据。
  final List<T> asks;

  /// 当前数据适配器。
  final DeepChartDataAdapter<T> adapter;

  /// 当前主题配置。
  final DeepChartTheme theme;

  /// 当前布局配置。
  final DeepChartLayoutConfig layout;

  /// 当前组件视口尺寸。
  final Size viewportSize;

  /// 已完成累计数量和坐标计算的节点集合。
  final DeepDepthNodes nodes;
}

/// 默认深度图布局工具。
///
/// 这些工具被默认 delegate 使用，也可以被自定义 delegate 复用。
abstract final class DeepChartDefaultLayoutUtils {
  /// 将买卖盘原始档位分别转换为累计深度节点。
  static DeepDepthNodes buildCumulativeDepthNodes({
    required List<DeepDepthEntry> bids,
    required List<DeepDepthEntry> asks,
  }) {
    return DeepDepthNodes(bids: _accumulate(bids), asks: _accumulate(asks));
  }

  /// 根据内容区域为累计深度节点计算画布坐标。
  ///
  /// 买盘从中线向左展开，卖盘从中线向右展开；Y 轴使用双边最大累计数量归一化。
  static DeepDepthNodes buildPositionedDepthNodes({
    required DeepDepthNodes nodes,
    required Rect contentRect,
    required double centerGap,
  }) {
    final maxSize = nodes.maxCumulativeSize;
    if (maxSize <= 0) return nodes;

    final centerX = contentRect.center.dx;
    final bidRight = centerX - centerGap / 2;
    final askLeft = centerX + centerGap / 2;
    final bidWidth = bidRight - contentRect.left;
    final askWidth = contentRect.right - askLeft;

    return DeepDepthNodes(
      bids: [
        for (var i = 0; i < nodes.bids.length; i++)
          nodes.bids[i].copyWith(
            position: Offset(
              nodes.bids.length <= 1
                  ? bidRight
                  : bidRight - bidWidth * i / (nodes.bids.length - 1),
              _sizeToY(nodes.bids[i].cumulativeSize, maxSize, contentRect),
            ),
          ),
      ],
      asks: [
        for (var i = 0; i < nodes.asks.length; i++)
          nodes.asks[i].copyWith(
            position: Offset(
              nodes.asks.length <= 1
                  ? askLeft
                  : askLeft + askWidth * i / (nodes.asks.length - 1),
              _sizeToY(nodes.asks[i].cumulativeSize, maxSize, contentRect),
            ),
          ),
      ],
    );
  }

  /// 构建内容区域内的网格线。
  static List<DeepChartGridLine> buildGridLines({
    required Rect contentRect,
    required int horizontalCount,
    required int verticalCount,
  }) {
    return [
      for (var i = 0; i <= horizontalCount; i++)
        DeepChartGridLine(
          start: Offset(
            contentRect.left,
            contentRect.top + contentRect.height * i / horizontalCount,
          ),
          end: Offset(
            contentRect.right,
            contentRect.top + contentRect.height * i / horizontalCount,
          ),
        ),
      for (var i = 0; i <= verticalCount; i++)
        DeepChartGridLine(
          start: Offset(
            contentRect.left + contentRect.width * i / verticalCount,
            contentRect.top,
          ),
          end: Offset(
            contentRect.left + contentRect.width * i / verticalCount,
            contentRect.bottom,
          ),
        ),
    ];
  }

  /// 构建右侧累计数量标签的左上角坐标。
  ///
  /// 标签紧贴对应横向网格线的上方。
  static List<Offset> buildRightAxisLabelOffsets({
    required Rect contentRect,
    required double chartWidth,
    required double labelHeight,
    required int horizontalCount,
    double rightInset = 58,
  }) {
    return [
      for (var i = 0; i <= horizontalCount; i++)
        Offset(
          chartWidth - rightInset,
          contentRect.top +
              contentRect.height * i / horizontalCount -
              labelHeight,
        ),
    ];
  }

  /// 构建底部价格标签左上角坐标。
  ///
  /// 保留该方法用于简单偏移场景；默认 UI 当前使用 [buildBottomPriceLabelLayouts]。
  static List<Offset> buildBottomPriceLabelOffsets({
    required Rect contentRect,
    required double labelWidth,
    required double labelTop,
    required int priceLabelCount,
  }) {
    return [
      for (var i = 0; i < priceLabelCount; i++)
        Offset(
          contentRect.left +
              contentRect.width *
                  (priceLabelCount == 1 ? 0 : i / (priceLabelCount - 1)) -
              labelWidth / 2,
          labelTop,
        ),
    ];
  }

  /// 构建底部价格标签布局。
  ///
  /// 首尾标签分别左对齐和右对齐，中间标签按竖向网格线居中。
  /// [bottomPadding] 会从可绘制文本区域中扣除，用于给文本到底部边界保留距离。
  static List<DeepChartTextLayout> buildBottomPriceLabelLayouts({
    required Rect contentRect,
    required double chartWidth,
    required double rowTop,
    required double rowHeight,
    double bottomPadding = 0,
    required int priceLabelCount,
    required int verticalCount,
  }) {
    if (priceLabelCount <= 0) return const [];
    final drawableRowHeight = (rowHeight - bottomPadding).clamp(0.0, rowHeight);
    return [
      for (var i = 0; i < priceLabelCount; i++)
        DeepChartTextLayout(
          rect: _bottomLabelRect(
            contentRect: contentRect,
            rowHeight: drawableRowHeight,
            anchorX:
                contentRect.left +
                contentRect.width *
                    (verticalCount == 0 ? 0 : i / verticalCount),
            rowTop: rowTop,
            index: i,
            count: priceLabelCount,
          ),
          textAlign: switch (i) {
            0 => TextAlign.left,
            _ when i == priceLabelCount - 1 => TextAlign.right,
            _ => TextAlign.center,
          },
        ),
    ];
  }

  /// 构建底部最终分隔线。
  ///
  /// 线条位于组件整体高度内侧，避免被裁剪。
  static DeepChartGridLine buildBottomSeparatorLine({
    required Rect contentRect,
    required double totalHeight,
    double strokeWidth = 1,
  }) {
    final y = totalHeight - strokeWidth / 2;
    return DeepChartGridLine(
      start: Offset(contentRect.left, y),
      end: Offset(contentRect.right, y),
    );
  }

  /// 根据锚点构建单个底部价格标签区域。
  static Rect _bottomLabelRect({
    required Rect contentRect,
    required double rowHeight,
    required double anchorX,
    required double rowTop,
    required int index,
    required int count,
  }) {
    final width =
        count <= 1 ? contentRect.width : contentRect.width / (count - 1);
    final left = switch (index) {
      0 => contentRect.left,
      _ when index == count - 1 => contentRect.right - width,
      _ => anchorX - width / 2,
    };
    return Rect.fromLTWH(left, rowTop, width, rowHeight);
  }

  /// 计算一侧深度档位的累计数量。
  static List<DeepDepthNode> _accumulate(List<DeepDepthEntry> entries) {
    var cumulative = 0.0;
    return [
      for (var i = 0; i < entries.length; i++)
        DeepDepthNode(
          index: i,
          entry: entries[i],
          cumulativeSize: cumulative += entries[i].size,
        ),
    ];
  }

  /// 将累计数量映射到内容区域的 Y 坐标。
  static double _sizeToY(double size, double maxSize, Rect rect) {
    if (maxSize <= 0) return rect.bottom;
    return rect.bottom - rect.height * (size / maxSize);
  }
}

/// 深度图绘制代理。
///
/// core 只负责准备上下文并调度 delegate；业务方可以继承该类来自定义高度、
/// 布局节点、网格、曲线、覆盖层等。
abstract class DeepChartDelegate<T> {
  /// 创建深度图 delegate。
  const DeepChartDelegate();

  /// 返回组件整体高度。
  ///
  /// 默认高度为中间图形区域高度加底部数字行高度。
  double chartHeight(DeepChartContext<T> context) =>
      context.layout.mainHeight + context.layout.bottomHeight;

  /// 返回用于绘制的买卖盘布局节点。
  DeepDepthNodes getLayoutNodes(DeepChartContext<T> context) {
    final cumulativeNodes =
        DeepChartDefaultLayoutUtils.buildCumulativeDepthNodes(
          bids: context.bids.map(context.adapter.entry).toList(),
          asks: context.asks.map(context.adapter.entry).toList(),
        );
    return DeepChartDefaultLayoutUtils.buildPositionedDepthNodes(
      nodes: cumulativeNodes,
      contentRect: context.layout.contentRectFor(context.viewportSize),
      centerGap: context.layout.centerGap,
    );
  }

  /// 绘制固定网格和坐标轴文本。
  void drawGrid(Canvas canvas, Size size, DeepChartContext<T> context) {}

  /// 绘制买卖盘累计深度曲线和面积。
  void drawChart(Canvas canvas, Size size, DeepChartContext<T> context) {}

  /// 构建固定覆盖层，例如图例、徽标或自定义按钮。
  Widget? buildOverlayView(
    BuildContext context,
    DeepChartContext<T> chartContext,
  ) {
    return null;
  }
}
