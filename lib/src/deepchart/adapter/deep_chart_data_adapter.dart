import 'package:kline_flutter/src/deepchart/model/deep_depth_entry.dart';

/// 深度图数据适配器。
///
/// package 不要求业务数据继承固定模型。外部只需要通过该适配器告诉
/// `DeepChart` 如何从业务对象中读取价格和数量。
abstract class DeepChartDataAdapter<T> {
  /// 创建深度图数据适配器。
  const DeepChartDataAdapter();

  /// 返回当前盘口档位的价格。
  double price(T item);

  /// 返回当前盘口档位在该价格上的数量。
  double size(T item);

  /// 将业务对象转换为默认深度图内部使用的标准档位对象。
  DeepDepthEntry entry(T item) {
    return DeepDepthEntry(price: price(item), size: size(item));
  }
}

/// `DeepDepthEntry` 自身的默认适配器。
///
/// 当业务方已经直接使用 `DeepDepthEntry` 作为数据源时，可以直接复用该适配器。
class DeepDepthEntryAdapter extends DeepChartDataAdapter<DeepDepthEntry> {
  /// 创建默认深度档位适配器。
  const DeepDepthEntryAdapter();

  /// 返回档位价格。
  @override
  double price(DeepDepthEntry item) => item.price;

  /// 返回档位数量。
  @override
  double size(DeepDepthEntry item) => item.size;
}
