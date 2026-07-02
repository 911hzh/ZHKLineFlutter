import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:kline_flutter/src/kline/delegate/kline_chart_delegate.dart';

typedef KLineIndicatorValueGetter<T> = double? Function(T item);

typedef KLineIndicatorRenderer<T> =
    void Function(
      Canvas canvas,
      Rect rect,
      KLineChartContext<T> context,
      KLineDataAdapter<T> adapter,
      KLineIndicatorSpec<T> indicator,
    );

typedef KLineIndicatorHeightGetter<T> =
    double Function(
      KLineChartContext<T> context,
      KLineIndicatorSpec<T> indicator,
    );

/// 一条指标线的数据定义。
@immutable
class KLineIndicatorSeries<T> {
  const KLineIndicatorSeries({
    required this.id,
    required this.label,
    required this.colorIndex,
    this.value,
  });

  /// 指标值 id，例如 `ma5`、`cci14`。
  final String id;

  /// 指标标签名，例如 `MA5`、`DIF`。
  final String label;

  /// 使用 [KLineTheme.indicatorColorAt] 取色的颜色索引。
  final int colorIndex;

  /// 自定义取值；为空时走 [KLineDataAdapter.indicatorValue]。
  final KLineIndicatorValueGetter<T>? value;

  double? valueOf(T item, KLineDataAdapter<T> adapter) {
    return value?.call(item) ?? adapter.indicatorValue(item, id);
  }
}

/// 一个可选择、可绘制的指标定义。
@immutable
class KLineIndicatorSpec<T> {
  const KLineIndicatorSpec({
    required this.id,
    required this.label,
    this.series = const [],
    this.height,
    this.renderer,
  });

  /// 稳定唯一标识，用于 [KLineController.activeIndicatorIds]。
  final String id;

  /// 指标选择器展示文案。
  final String label;

  /// 默认折线绘制和标签展示使用的数据线。
  final List<KLineIndicatorSeries<T>> series;

  /// 副图高度；为空时使用 [KLineLayoutConfig.secondaryPaneHeight]。
  final double? height;

  /// 自定义绘制策略；为空时使用默认折线绘制。
  final KLineIndicatorRenderer<T>? renderer;
}

/// 默认 K 线指标 id 与定义工厂。
abstract final class KLineDefaultIndicators {
  static const maId = 'ma';
  static const emaId = 'ema';
  static const bollId = 'boll';
  static const volumeId = 'volume';
  static const macdId = 'macd';
  static const kdjId = 'kdj';
  static const rsiId = 'rsi';
  static const wrId = 'wr';

  static const ma5 = 'ma5';
  static const ma10 = 'ma10';
  static const ma30 = 'ma30';
  static const ema5 = 'ema5';
  static const ema10 = 'ema10';
  static const ema30 = 'ema30';
  static const bollUpper = 'bollUpper';
  static const bollMiddle = 'bollMiddle';
  static const bollLower = 'bollLower';
  static const macdValue = 'macd';
  static const dif = 'dif';
  static const dea = 'dea';
  static const k = 'k';
  static const d = 'd';
  static const j = 'j';
  static const rsi6 = 'rsi6';
  static const rsi12 = 'rsi12';
  static const rsi24 = 'rsi24';
  static const wr6 = 'wr6';
  static const wr10 = 'wr10';
  static const wr14 = 'wr14';
  static const volumeMA5 = 'volumeMA5';
  static const volumeMA10 = 'volumeMA10';

  static KLineIndicatorSpec<T> ma<T>() {
    return KLineIndicatorSpec<T>(
      id: maId,
      label: 'MA',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: ma5, label: 'MA5', colorIndex: 0),
        KLineIndicatorSeries<T>(id: ma10, label: 'MA10', colorIndex: 1),
        KLineIndicatorSeries<T>(id: ma30, label: 'MA30', colorIndex: 2),
      ],
    );
  }

  static KLineIndicatorSpec<T> ema<T>() {
    return KLineIndicatorSpec<T>(
      id: emaId,
      label: 'EMA',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: ema5, label: 'EMA5', colorIndex: 3),
        KLineIndicatorSeries<T>(id: ema10, label: 'EMA10', colorIndex: 4),
        KLineIndicatorSeries<T>(id: ema30, label: 'EMA30', colorIndex: 5),
      ],
    );
  }

  static KLineIndicatorSpec<T> boll<T>() {
    return KLineIndicatorSpec<T>(
      id: bollId,
      label: 'BOLL',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: bollUpper, label: 'UB', colorIndex: 0),
        KLineIndicatorSeries<T>(id: bollMiddle, label: 'MB', colorIndex: 1),
        KLineIndicatorSeries<T>(id: bollLower, label: 'LB', colorIndex: 2),
      ],
    );
  }

  static KLineIndicatorSpec<T> volume<T>() {
    return KLineIndicatorSpec<T>(
      id: volumeId,
      label: 'VOL',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: volumeMA5, label: 'MA5', colorIndex: 1),
        KLineIndicatorSeries<T>(id: volumeMA10, label: 'MA10', colorIndex: 3),
      ],
    );
  }

  static KLineIndicatorSpec<T> macd<T>() {
    return KLineIndicatorSpec<T>(
      id: macdId,
      label: 'MACD',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: dif, label: 'DIF', colorIndex: 1),
        KLineIndicatorSeries<T>(id: dea, label: 'DEA', colorIndex: 3),
        KLineIndicatorSeries<T>(id: macdValue, label: 'MACD', colorIndex: 0),
      ],
    );
  }

  static KLineIndicatorSpec<T> kdj<T>() {
    return KLineIndicatorSpec<T>(
      id: kdjId,
      label: 'KDJ',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: k, label: 'K', colorIndex: 1),
        KLineIndicatorSeries<T>(id: d, label: 'D', colorIndex: 3),
        KLineIndicatorSeries<T>(id: j, label: 'J', colorIndex: 2),
      ],
    );
  }

  static KLineIndicatorSpec<T> rsi<T>() {
    return KLineIndicatorSpec<T>(
      id: rsiId,
      label: 'RSI',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: rsi6, label: 'RSI6', colorIndex: 3),
        KLineIndicatorSeries<T>(id: rsi12, label: 'RSI12', colorIndex: 4),
        KLineIndicatorSeries<T>(id: rsi24, label: 'RSI24', colorIndex: 1),
      ],
    );
  }

  static KLineIndicatorSpec<T> wr<T>() {
    return KLineIndicatorSpec<T>(
      id: wrId,
      label: 'WR',
      series: <KLineIndicatorSeries<T>>[
        KLineIndicatorSeries<T>(id: wr6, label: 'WR6', colorIndex: 3),
        KLineIndicatorSeries<T>(id: wr10, label: 'WR10', colorIndex: 4),
        KLineIndicatorSeries<T>(id: wr14, label: 'WR14', colorIndex: 1),
      ],
    );
  }

  static List<KLineIndicatorSpec<T>> main<T>() {
    return [ma<T>(), ema<T>(), boll<T>()];
  }

  static List<KLineIndicatorSpec<T>> secondary<T>() {
    return [volume<T>(), macd<T>(), kdj<T>(), rsi<T>(), wr<T>()];
  }
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

  /// 返回指标 id 对应的数值；没有该指标时返回 null。
  double? indicatorValue(T item, String valueId) => null;

  /// 返回主图指标左上角标签展示项。
  List<KLineIndicatorEntry> mainIndicatorEntries(
    T item,
    KLineIndicatorSpec<T> indicator,
  ) {
    return indicatorEntries(item, indicator);
  }

  /// 返回副图指标左上角标签展示项。
  List<KLineIndicatorEntry> secondaryIndicatorEntries(
    T item,
    KLineIndicatorSpec<T> indicator,
  ) {
    return indicatorEntries(item, indicator);
  }

  /// 按指标定义生成默认标签展示项。
  List<KLineIndicatorEntry> indicatorEntries(
    T item,
    KLineIndicatorSpec<T> indicator,
  ) {
    return [
      for (final series in indicator.series)
        KLineIndicatorEntry(
          label: series.label,
          value: series.valueOf(item, this),
          colorIndex: series.colorIndex,
        ),
    ];
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
