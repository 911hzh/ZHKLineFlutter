import 'dart:math' as math;
import 'package:k_line_flutter/kline/models/KLineResponse.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorsModel.dart';

/// 数据计算工具类
class DataUtil {
  /// 计算简单移动平均线 (Simple Moving Average)
  static List<double?> calculateMA(List<double> prices, int period) {
    List<double?> results = List.filled(prices.length, null);

    if (prices.length < period) return results;

    for (int i = period - 1; i < prices.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += prices[j];
      }
      results[i] = sum / period;
    }

    return results;
  }

  /// 计算指数移动平均线 (Exponential Moving Average)
  static List<double?> calculateEMA(List<double> prices, int period) {
    List<double?> results = List.filled(prices.length, null);

    if (prices.length < period) return results;

    final multiplier = 2.0 / (period + 1.0);

    // 第一个EMA值是SMA
    double smaSum = 0;
    for (int i = 0; i < period; i++) {
      smaSum += prices[i];
    }
    results[period - 1] = smaSum / period;

    // 计算后续EMA值
    for (int i = period; i < prices.length; i++) {
      final previousEMA = results[i - 1];
      if (previousEMA != null) {
        results[i] = (prices[i] - previousEMA) * multiplier + previousEMA;
      }
    }

    return results;
  }

  /// 计算布林带 (Bollinger Bands)
  static ({List<double?> upper, List<double?> middle, List<double?> lower}) calculateBOLL(
    List<double> prices, {
    int period = 20,
    double multiplier = 2.0,
  }) {
    final ma = calculateMA(prices, period);
    List<double?> upper = List.filled(prices.length, null);
    List<double?> lower = List.filled(prices.length, null);

    for (int i = period - 1; i < prices.length; i++) {
      final middleValue = ma[i];
      if (middleValue != null) {
        // 计算标准差
        double sum = 0;
        for (int j = i - period + 1; j <= i; j++) {
          sum += math.pow(prices[j] - middleValue, 2);
        }
        final standardDeviation = math.sqrt(sum / period);

        upper[i] = middleValue + multiplier * standardDeviation;
        lower[i] = middleValue - multiplier * standardDeviation;
      }
    }

    return (upper: upper, middle: ma, lower: lower);
  }

  /// 计算MACD指标
  static ({List<double?> macd, List<double?> dif, List<double?> dea}) calculateMACD(
    List<double> prices, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    final ema12 = calculateEMA(prices, fastPeriod);
    final ema26 = calculateEMA(prices, slowPeriod);

    List<double?> dif = List.filled(prices.length, null);

    // 计算DIF线
    for (int i = 0; i < prices.length; i++) {
      final fast = ema12[i];
      final slow = ema26[i];
      if (fast != null && slow != null) {
        dif[i] = fast - slow;
      }
    }

    // 计算DEA线（DIF的EMA）
    final difValues = dif.whereType<double>().toList();
    final deaResults = calculateEMA(difValues, signalPeriod);
    List<double?> dea = List.filled(prices.length, null);

    int deaIndex = 0;
    for (int i = 0; i < dif.length; i++) {
      if (dif[i] != null) {
        if (deaIndex < deaResults.length) {
          dea[i] = deaResults[deaIndex];
        }
        deaIndex++;
      }
    }

    // 计算MACD柱
    List<double?> macd = List.filled(prices.length, null);
    for (int i = 0; i < prices.length; i++) {
      final difValue = dif[i];
      final deaValue = dea[i];
      if (difValue != null && deaValue != null) {
        macd[i] = 2 * (difValue - deaValue);
      }
    }

    return (macd: macd, dif: dif, dea: dea);
  }

  /// 计算KDJ指标
  static ({List<double?> k, List<double?> d, List<double?> j}) calculateKDJ(
    List<KLineData> klineData, {
    int period = 9,
    int m1 = 3,
    int m2 = 3,
  }) {
    List<double?> k = List.filled(klineData.length, null);
    List<double?> d = List.filled(klineData.length, null);
    List<double?> j = List.filled(klineData.length, null);

    if (klineData.length < period) {
      return (k: k, d: d, j: j);
    }

    List<double> rsv = [];

    // 计算RSV
    for (int i = period - 1; i < klineData.length; i++) {
      final periodData = klineData.sublist(i - period + 1, i + 1);
      final highest = periodData.map((e) => e.high).reduce(math.max);
      final lowest = periodData.map((e) => e.low).reduce(math.min);
      final close = klineData[i].close;

      final rsvValue = highest == lowest ? 50.0 : ((close - lowest) / (highest - lowest)) * 100;
      rsv.add(rsvValue);
    }

    // 计算K、D、J值
    double kValue = 50.0;
    double dValue = 50.0;

    for (int i = 0; i < rsv.length; i++) {
      kValue = ((m1 - 1) * kValue + rsv[i]) / m1;
      dValue = ((m2 - 1) * dValue + kValue) / m2;
      final jValue = 3 * kValue - 2 * dValue;

      final index = i + period - 1;
      k[index] = kValue;
      d[index] = dValue;
      j[index] = jValue;
    }

    return (k: k, d: d, j: j);
  }

  /// 计算RSI相对强弱指标
  static List<double?> calculateRSI(List<double> prices, int period) {
    List<double?> results = List.filled(prices.length, null);

    if (prices.length <= period) return results;

    List<double> gains = [];
    List<double> losses = [];

    // 计算价格变化
    for (int i = 1; i < prices.length; i++) {
      final change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    // 计算RSI
    for (int i = period - 1; i < gains.length; i++) {
      double avgGain = 0;
      double avgLoss = 0;

      for (int j = i - period + 1; j <= i; j++) {
        avgGain += gains[j];
        avgLoss += losses[j];
      }

      avgGain /= period;
      avgLoss /= period;

      if (avgLoss == 0) {
        results[i + 1] = 100;
      } else {
        final rs = avgGain / avgLoss;
        results[i + 1] = 100 - (100 / (1 + rs));
      }
    }

    return results;
  }

  /// 计算成交量移动平均线
  static List<double?> calculateVolumeMA(List<double> volumes, int period) {
    return calculateMA(volumes, period);
  }

  /// 计算威廉指标(WR)
  static List<double?> calculateWR(List<KLineData> klineData, int period) {
    List<double?> results = List.filled(klineData.length, null);

    if (klineData.length < period) return results;

    for (int i = period - 1; i < klineData.length; i++) {
      final startIndex = i - period + 1;
      final endIndex = i;

      // 获取周期内的高低价
      final periodData = klineData.sublist(startIndex, endIndex + 1);
      final highs = periodData.map((e) => e.high).toList();
      final lows = periodData.map((e) => e.low).toList();

      final maxHigh = highs.reduce(math.max);
      final minLow = lows.reduce(math.min);

      final currentClose = klineData[i].close;

      // WR = (HN - C) / (HN - LN) * 100
      if (maxHigh != minLow) {
        final wr = (maxHigh - currentClose) / (maxHigh - minLow) * 100;
        results[i] = -wr; // WR通常为负值
      }
    }

    return results;
  }

  /// 将K线数据转换为带技术指标的KLineModel数组
  static List<KLineModel> toKLineModelsWithIndicators(List<KLineData> datas, KLinePeriod selectedPeriod) {
    final indicators = calculateAllIndicators(datas);

    // 使用map创建KLineModel并赋值技术指标
    return datas.asMap().entries.map((entry) {
      final index = entry.key;
      final klineData = entry.value;

      final model = KLineModel.fromKLineData(klineData, selectedPeriod);
      if (index < indicators.length) {
        model.kLineTechnicalIndicatorsModel = indicators[index];
      }
      return model;
    }).toList();
  }

  /// 为K线数据数组计算所有技术指标
  static List<KLineTechnicalIndicatorsModel> calculateAllIndicators(List<KLineData> klineData) {
    final closePrices = klineData.map((e) => e.close).toList();
    final volumes = klineData.map((e) => e.vol).toList();

    // 计算各种技术指标
    final ma5 = calculateMA(closePrices, 5);
    final ma10 = calculateMA(closePrices, 10);
    final ma30 = calculateMA(closePrices, 30);

    final ema5 = calculateEMA(closePrices, 5);
    final ema10 = calculateEMA(closePrices, 10);
    final ema30 = calculateEMA(closePrices, 30);

    final boll = calculateBOLL(closePrices);
    final macdData = calculateMACD(closePrices);
    final kdjData = calculateKDJ(klineData);

    final rsi6 = calculateRSI(closePrices, 6);
    final rsi12 = calculateRSI(closePrices, 12);
    final rsi24 = calculateRSI(closePrices, 24);

    final wr6 = calculateWR(klineData, 6);
    final wr10 = calculateWR(klineData, 10);
    final wr14 = calculateWR(klineData, 14);

    final volumeMA5 = calculateVolumeMA(volumes, 5);
    final volumeMA10 = calculateVolumeMA(volumes, 10);

    // 组装结果
    List<KLineTechnicalIndicatorsModel> indicators = [];

    for (int i = 0; i < klineData.length; i++) {
      final indicator = KLineTechnicalIndicatorsModel(
        ma5: ma5[i],
        ma10: ma10[i],
        ma30: ma30[i],
        ema5: ema5[i],
        ema10: ema10[i],
        ema30: ema30[i],
        bollUpper: boll.upper[i],
        bollMiddle: boll.middle[i],
        bollLower: boll.lower[i],
        macd: macdData.macd[i],
        dif: macdData.dif[i],
        dea: macdData.dea[i],
        k: kdjData.k[i],
        d: kdjData.d[i],
        j: kdjData.j[i],
        rsi6: rsi6[i],
        rsi12: rsi12[i],
        rsi24: rsi24[i],
        wr6: wr6[i],
        wr10: wr10[i],
        wr14: wr14[i],
        volumeMA5: volumeMA5[i],
        volumeMA10: volumeMA10[i],
      );
      indicators.add(indicator);
    }

    return indicators;
  }
}
