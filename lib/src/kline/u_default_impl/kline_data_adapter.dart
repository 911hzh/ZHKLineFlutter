import 'package:flutter/foundation.dart';

/// 默认 K 线实现支持的指标类型。
enum KLineDefaultIndicatorType {
  /// 主图 MA 指标。
  ma,

  /// 主图 EMA 指标。
  ema,

  /// 主图 BOLL 指标。
  boll,

  /// 副图成交量指标。
  volume,

  /// 副图 MACD 指标。
  macd,

  /// 副图 KDJ 指标。
  kdj,

  /// 副图 RSI 指标。
  rsi,

  /// 副图 WR 指标。
  wr;

  /// 默认主图指标列表。
  static const mainTypes = [
    KLineDefaultIndicatorType.ma,
    KLineDefaultIndicatorType.ema,
    KLineDefaultIndicatorType.boll,
  ];

  /// 默认副图指标列表。
  static const secondaryTypes = [
    KLineDefaultIndicatorType.volume,
    KLineDefaultIndicatorType.macd,
    KLineDefaultIndicatorType.kdj,
    KLineDefaultIndicatorType.rsi,
    KLineDefaultIndicatorType.wr,
  ];

  /// 当前指标是否绘制在主图区域。
  bool get isMainType => mainTypes.contains(this);

  /// 当前指标是否绘制在副图区域。
  bool get isSecondaryType => secondaryTypes.contains(this);

  /// 默认指标选择器展示文案。
  String get label {
    return switch (this) {
      KLineDefaultIndicatorType.ma => 'MA',
      KLineDefaultIndicatorType.ema => 'EMA',
      KLineDefaultIndicatorType.boll => 'BOLL',
      KLineDefaultIndicatorType.volume => 'VOL',
      KLineDefaultIndicatorType.macd => 'MACD',
      KLineDefaultIndicatorType.kdj => 'KDJ',
      KLineDefaultIndicatorType.rsi => 'RSI',
      KLineDefaultIndicatorType.wr => 'WR',
    };
  }
}

/// 默认 K 线实现可读取的指标数值。
enum KLineDefaultIndicatorValue {
  /// MA 5 周期数值。
  ma5,

  /// MA 10 周期数值。
  ma10,

  /// MA 30 周期数值。
  ma30,

  /// EMA 5 周期数值。
  ema5,

  /// EMA 10 周期数值。
  ema10,

  /// EMA 30 周期数值。
  ema30,

  /// BOLL 上轨。
  bollUpper,

  /// BOLL 中轨。
  bollMiddle,

  /// BOLL 下轨。
  bollLower,

  /// MACD 柱状值。
  macd,

  /// MACD DIF 线。
  dif,

  /// MACD DEA 线。
  dea,

  /// KDJ K 值。
  k,

  /// KDJ D 值。
  d,

  /// KDJ J 值。
  j,

  /// RSI 6 周期值。
  rsi6,

  /// RSI 12 周期值。
  rsi12,

  /// RSI 24 周期值。
  rsi24,

  /// WR 6 周期值。
  wr6,

  /// WR 10 周期值。
  wr10,

  /// WR 14 周期值。
  wr14,

  /// 成交量 MA 5 周期值。
  volumeMA5,

  /// 成交量 MA 10 周期值。
  volumeMA10,
}

/// 默认详情面板中的一行展示数据。
@immutable
class KLineDetailEntry {
  /// 创建一行详情展示数据。
  const KLineDetailEntry(this.label, this.value);

  /// 详情字段名。
  final String label;

  /// 已格式化后的详情字段值。
  final String value;
}

/// 默认指标标签中的一个展示项。
@immutable
class KLineIndicatorEntry {
  /// 创建一个指标标签展示项。
  const KLineIndicatorEntry({
    required this.label,
    required this.value,
    required this.colorIndex,
  });

  /// 指标标签名，例如 `MA5`、`DIF`。
  final String label;

  /// 指标数值；为 null 时默认标签 UI 不展示该项。
  final double? value;

  /// 使用 [KLineTheme.indicatorColorAt] 取色的颜色索引。
  final int colorIndex;
}

/// 将业务 K 线模型适配为默认绘制实现需要的字段。
///
/// 使用 adapter 可以避免要求用户的实体类继承某个 package model。
abstract class KLineDataAdapter<T> {
  const KLineDataAdapter();

  /// 返回开盘价。
  double open(T item);

  /// 返回最高价。
  double high(T item);

  /// 返回最低价。
  double low(T item);

  /// 返回收盘价。
  double close(T item);

  /// 返回成交量。
  double volume(T item);

  /// 返回底部时间轴与详情面板使用的日期文案。
  String dateLabel(T item);

  /// 返回默认指标对应的数值；没有该指标时返回 null。
  double? indicatorValue(T item, KLineDefaultIndicatorValue value) => null;

  /// 返回主图指标左上角标签展示项。
  ///
  /// 默认实现使用常见的 MA/EMA/BOLL 参数。业务方可以覆盖该方法来自定义
  /// 指标名称、顺序、颜色索引或指标参数，例如 MA7/MA25。
  List<KLineIndicatorEntry> mainIndicatorEntries(
    T item,
    KLineDefaultIndicatorType type,
  ) {
    return switch (type) {
      KLineDefaultIndicatorType.ma => [
        KLineIndicatorEntry(
          label: 'MA5',
          value: indicatorValue(item, KLineDefaultIndicatorValue.ma5),
          colorIndex: 0,
        ),
        KLineIndicatorEntry(
          label: 'MA10',
          value: indicatorValue(item, KLineDefaultIndicatorValue.ma10),
          colorIndex: 1,
        ),
        KLineIndicatorEntry(
          label: 'MA30',
          value: indicatorValue(item, KLineDefaultIndicatorValue.ma30),
          colorIndex: 2,
        ),
      ],
      KLineDefaultIndicatorType.ema => [
        KLineIndicatorEntry(
          label: 'EMA5',
          value: indicatorValue(item, KLineDefaultIndicatorValue.ema5),
          colorIndex: 3,
        ),
        KLineIndicatorEntry(
          label: 'EMA10',
          value: indicatorValue(item, KLineDefaultIndicatorValue.ema10),
          colorIndex: 4,
        ),
        KLineIndicatorEntry(
          label: 'EMA30',
          value: indicatorValue(item, KLineDefaultIndicatorValue.ema30),
          colorIndex: 5,
        ),
      ],
      KLineDefaultIndicatorType.boll => [
        KLineIndicatorEntry(
          label: 'UPPER',
          value: indicatorValue(item, KLineDefaultIndicatorValue.bollUpper),
          colorIndex: 0,
        ),
        KLineIndicatorEntry(
          label: 'MB',
          value: indicatorValue(item, KLineDefaultIndicatorValue.bollMiddle),
          colorIndex: 1,
        ),
        KLineIndicatorEntry(
          label: 'LOWER',
          value: indicatorValue(item, KLineDefaultIndicatorValue.bollLower),
          colorIndex: 2,
        ),
      ],
      _ => const [],
    };
  }

  /// 返回副图指标左上角标签展示项。
  ///
  /// 默认实现使用 VOL、MACD、KDJ、RSI、WR 的常见展示字段。
  List<KLineIndicatorEntry> secondaryIndicatorEntries(
    T item,
    KLineDefaultIndicatorType type,
  ) {
    return switch (type) {
      KLineDefaultIndicatorType.volume => [
        KLineIndicatorEntry(
          label: 'MA5',
          value: indicatorValue(item, KLineDefaultIndicatorValue.volumeMA5),
          colorIndex: 1,
        ),
        KLineIndicatorEntry(
          label: 'MA10',
          value: indicatorValue(item, KLineDefaultIndicatorValue.volumeMA10),
          colorIndex: 3,
        ),
      ],
      KLineDefaultIndicatorType.macd => [
        KLineIndicatorEntry(
          label: 'DIF',
          value: indicatorValue(item, KLineDefaultIndicatorValue.dif),
          colorIndex: 1,
        ),
        KLineIndicatorEntry(
          label: 'DEA',
          value: indicatorValue(item, KLineDefaultIndicatorValue.dea),
          colorIndex: 3,
        ),
        KLineIndicatorEntry(
          label: 'MACD',
          value: indicatorValue(item, KLineDefaultIndicatorValue.macd),
          colorIndex: 0,
        ),
      ],
      KLineDefaultIndicatorType.kdj => [
        KLineIndicatorEntry(
          label: 'K',
          value: indicatorValue(item, KLineDefaultIndicatorValue.k),
          colorIndex: 1,
        ),
        KLineIndicatorEntry(
          label: 'D',
          value: indicatorValue(item, KLineDefaultIndicatorValue.d),
          colorIndex: 3,
        ),
        KLineIndicatorEntry(
          label: 'J',
          value: indicatorValue(item, KLineDefaultIndicatorValue.j),
          colorIndex: 2,
        ),
      ],
      KLineDefaultIndicatorType.rsi => [
        KLineIndicatorEntry(
          label: 'RSI6',
          value: indicatorValue(item, KLineDefaultIndicatorValue.rsi6),
          colorIndex: 3,
        ),
        KLineIndicatorEntry(
          label: 'RSI12',
          value: indicatorValue(item, KLineDefaultIndicatorValue.rsi12),
          colorIndex: 4,
        ),
        KLineIndicatorEntry(
          label: 'RSI24',
          value: indicatorValue(item, KLineDefaultIndicatorValue.rsi24),
          colorIndex: 1,
        ),
      ],
      KLineDefaultIndicatorType.wr => [
        KLineIndicatorEntry(
          label: 'WR6',
          value: indicatorValue(item, KLineDefaultIndicatorValue.wr6),
          colorIndex: 3,
        ),
        KLineIndicatorEntry(
          label: 'WR10',
          value: indicatorValue(item, KLineDefaultIndicatorValue.wr10),
          colorIndex: 4,
        ),
        KLineIndicatorEntry(
          label: 'WR14',
          value: indicatorValue(item, KLineDefaultIndicatorValue.wr14),
          colorIndex: 1,
        ),
      ],
      _ => const [],
    };
  }

  /// 返回长按选中详情面板中的字段。
  ///
  /// 默认展示时间、开高低收和成交量；业务方可覆盖为本地化或更多字段。
  List<KLineDetailEntry> detailEntries(T item) {
    return [
      KLineDetailEntry('Time', dateLabel(item)),
      KLineDetailEntry('Open', open(item).toStringAsFixed(2)),
      KLineDetailEntry('High', high(item).toStringAsFixed(2)),
      KLineDetailEntry('Low', low(item).toStringAsFixed(2)),
      KLineDetailEntry('Close', close(item).toStringAsFixed(2)),
      KLineDetailEntry('Volume', volume(item).toStringAsFixed(2)),
    ];
  }
}
