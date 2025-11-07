import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/widgets/renderers/IndicatorRenderer.dart';
import 'package:k_line_flutter/kline/widgets/renderers/VolumeIndicatorRenderer.dart';
import 'package:k_line_flutter/kline/widgets/renderers/MacdIndicatorRenderer.dart';
import 'package:k_line_flutter/kline/widgets/renderers/KdjIndicatorRenderer.dart';
import 'package:k_line_flutter/kline/widgets/renderers/RsiIndicatorRenderer.dart';
import 'package:k_line_flutter/kline/widgets/renderers/WrIndicatorRenderer.dart';

/// 指标绘制器工厂类
class IndicatorRendererFactory {
  /// 根据指标类型创建对应的绘制器
  static IndicatorRenderer? createRenderer(KLineTechnicalIndicatorType indicatorType) {
    switch (indicatorType) {
      case KLineTechnicalIndicatorType.volume:
        return VolumeIndicatorRenderer();
      case KLineTechnicalIndicatorType.macd:
        return MACDIndicatorRenderer();
      case KLineTechnicalIndicatorType.kdj:
        return KDJIndicatorRenderer();
      case KLineTechnicalIndicatorType.rsi:
        return RSIIndicatorRenderer();
      case KLineTechnicalIndicatorType.wr:
        return WRIndicatorRenderer();
      default:
        return null; // 主图指标不在这里处理
    }
  }
}
