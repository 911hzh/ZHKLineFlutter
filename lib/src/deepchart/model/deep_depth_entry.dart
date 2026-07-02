import 'package:flutter/material.dart';

/// 单个盘口深度档位。
///
/// 对应行情接口里的 `[price, size]`：价格档位和该档位数量。
@immutable
class DeepDepthEntry {
  /// 创建盘口深度档位。
  const DeepDepthEntry({required this.price, required this.size});

  /// 当前档位价格。
  final double price;

  /// 当前档位数量。
  final double size;
}

/// 深度图绘制节点。
///
/// 节点在原始档位基础上补充了累计数量和绘制坐标，默认 delegate 使用它来绘制
/// 累计深度面积图。
@immutable
class DeepDepthNode {
  /// 创建深度图绘制节点。
  const DeepDepthNode({required this.index, required this.entry, required this.cumulativeSize, this.position});

  /// 当前节点在买盘或卖盘数组中的下标。
  final int index;

  /// 当前节点对应的原始盘口档位。
  final DeepDepthEntry entry;

  /// 从第一个档位累计到当前档位的数量。
  final double cumulativeSize;

  /// 当前节点在画布坐标系中的位置。
  ///
  /// `null` 表示该节点尚未完成布局计算。
  final Offset? position;

  /// 当前节点价格。
  double get price => entry.price;

  /// 当前节点原始档位数量。
  double get size => entry.size;

  /// 复制节点并替换部分布局字段。
  DeepDepthNode copyWith({Offset? position}) {
    return DeepDepthNode(
      index: index,
      entry: entry,
      cumulativeSize: cumulativeSize,
      position: position ?? this.position,
    );
  }
}

/// 买盘和卖盘的深度图节点集合。
@immutable
class DeepDepthNodes {
  /// 创建双边深度节点集合。
  const DeepDepthNodes({required this.bids, required this.asks});

  /// 买盘累计深度节点。
  final List<DeepDepthNode> bids;

  /// 卖盘累计深度节点。
  final List<DeepDepthNode> asks;

  /// 买卖盘是否都为空。
  bool get isEmpty => bids.isEmpty && asks.isEmpty;

  /// 买盘和卖盘中最大的累计数量，用作默认 Y 轴范围。
  double get maxCumulativeSize {
    var maxValue = 0.0;
    for (final node in [...bids, ...asks]) {
      if (node.cumulativeSize > maxValue) maxValue = node.cumulativeSize;
    }
    return maxValue;
  }

  /// 买卖盘中的最低价格，用作底部价格轴起点。
  double get minPrice {
    final prices = [...bids.map((node) => node.price), ...asks.map((node) => node.price)];
    if (prices.isEmpty) return 0;
    return prices.reduce((left, right) => left < right ? left : right);
  }

  /// 买卖盘中的最高价格，用作底部价格轴终点。
  double get maxPrice {
    final prices = [...bids.map((node) => node.price), ...asks.map((node) => node.price)];
    if (prices.isEmpty) return 0;
    return prices.reduce((left, right) => left > right ? left : right);
  }
}
