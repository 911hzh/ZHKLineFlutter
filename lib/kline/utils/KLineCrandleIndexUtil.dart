import 'dart:math' as math;
import 'dart:ui';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';

/// K线蜡烛索引计算工具类
class KLineCrandleIndexUtil {
  /// 计算出需要显示的蜡烛数据，以及位置信息，以及最大最小值等
  static ({
    List<KLineModel> showDatas,
    List<KLinePositionModel> positionModels,
    double maxPrice,
    double minPrice,
    int indexBegin,
    int indexEnd,
  })
  computerSize({
    required List<KLineModel> datas,
    required double drawMaxWidth,
    required double offset,
    required double crandleWidth,
    required double crandleSpace,
    required double totalHeight,
    List<KLineTechnicalIndicatorType> indicatorSelection = const [],
  }) {
    // 获取可见范围的索引
    final indexResult = _findStartAndEndIndex(
      drawMaxWidth: drawMaxWidth,
      offset: offset,
      crandleWidth: crandleWidth,
      crandleSpace: crandleSpace,
      datasCount: datas.length,
    );

    if (indexResult.$1 < 0 || indexResult.$2 > datas.length) {
      print("array beyond");
      return (
        showDatas: <KLineModel>[],
        positionModels: <KLinePositionModel>[],
        maxPrice: 0.0,
        minPrice: 0.0,
        indexBegin: 0,
        indexEnd: 0,
      );
    }

    print("index: begin: ${indexResult.$1}, end: ${indexResult.$2}");

    // 提取可见范围内的数据
    final showedArray = datas.sublist(indexResult.$1, indexResult.$2 + 1);

    // 计算可见数据的最大和最小价格（包含技术指标）
    final priceResult = _findMaxAndMinPrice(
      showedArray: showedArray,
      indicatorSelection: indicatorSelection,
    );

    List<KLinePositionModel> positionModels = [];
    final config = KLineConfig.shared;

    for (int i = indexResult.$1; i <= indexResult.$2; i++) {
      final itemX = i * (config.candleSpace + config.candleWidth);
      final item = datas[i].klineData;
      final klineModel = datas[i];

      // 计算基础K线位置
      // 注意：Flutter的SingleChildScrollView会自动处理滚动偏移，所以这里不需要减去offset
      // Swift版本需要减offset是因为chartView.frame.origin.x被设置为offset
      final centerX =
          itemX + config.crandleInsets.left + config.candleWidth / 2;

      // 计算当前K线的技术指标位置
      SingleIndicatorPosition? indicatorPosition;
      final indicators = klineModel.kLineTechnicalIndicatorsModel;

      if (indicators != null) {
        indicatorPosition = SingleIndicatorPosition();

        // MA指标位置
        if (indicatorSelection.contains(KLineTechnicalIndicatorType.ma)) {
          final ma5 = indicators.ma5;
          if (ma5 != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: ma5,
                  totalHeight: totalHeight,
                );
            indicatorPosition.ma5Point = Offset(centerX, y);
          }

          final ma10 = indicators.ma10;
          if (ma10 != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: ma10,
                  totalHeight: totalHeight,
                );
            indicatorPosition.ma10Point = Offset(centerX, y);
          }

          final ma30 = indicators.ma30;
          if (ma30 != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: ma30,
                  totalHeight: totalHeight,
                );
            indicatorPosition.ma30Point = Offset(centerX, y);
          }
        }

        // EMA指标位置
        if (indicatorSelection.contains(KLineTechnicalIndicatorType.ema)) {
          final ema5 = indicators.ema5;
          if (ema5 != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: ema5,
                  totalHeight: totalHeight,
                );
            indicatorPosition.ema5Point = Offset(centerX, y);
          }

          final ema10 = indicators.ema10;
          if (ema10 != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: ema10,
                  totalHeight: totalHeight,
                );
            indicatorPosition.ema10Point = Offset(centerX, y);
          }

          final ema30 = indicators.ema30;
          if (ema30 != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: ema30,
                  totalHeight: totalHeight,
                );
            indicatorPosition.ema30Point = Offset(centerX, y);
          }
        }

        // BOLL指标位置
        if (indicatorSelection.contains(KLineTechnicalIndicatorType.boll)) {
          final bollUpper = indicators.bollUpper;
          if (bollUpper != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: bollUpper,
                  totalHeight: totalHeight,
                );
            indicatorPosition.bollUpperPoint = Offset(centerX, y);
          }

          final bollMiddle = indicators.bollMiddle;
          if (bollMiddle != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: bollMiddle,
                  totalHeight: totalHeight,
                );
            indicatorPosition.bollMiddlePoint = Offset(centerX, y);
          }

          final bollLower = indicators.bollLower;
          if (bollLower != null) {
            final y =
                totalHeight -
                _computerPositionY(
                  maxPrice: priceResult.maxPrice,
                  minPrice: priceResult.minPrice,
                  value: bollLower,
                  totalHeight: totalHeight,
                );
            indicatorPosition.bollLowerPoint = Offset(centerX, y);
          }
        }
      }

      final positionModel = KLinePositionModel(
        candleCenterX: centerX,
        candleWidth: config.candleWidth,
        candleBodyTopY: _computerPositionY(
          maxPrice: priceResult.maxPrice,
          minPrice: priceResult.minPrice,
          value: math.max(item.close, item.open),
          totalHeight: totalHeight,
        ),
        candleBodyBottomY: _computerPositionY(
          maxPrice: priceResult.maxPrice,
          minPrice: priceResult.minPrice,
          value: math.min(item.close, item.open),
          totalHeight: totalHeight,
        ),
        candleUpperWickTopY: _computerPositionY(
          maxPrice: priceResult.maxPrice,
          minPrice: priceResult.minPrice,
          value: item.high,
          totalHeight: totalHeight,
        ),
        candleLowerWickBottomY: _computerPositionY(
          maxPrice: priceResult.maxPrice,
          minPrice: priceResult.minPrice,
          value: item.low,
          totalHeight: totalHeight,
        ),
        indicatorPosition: indicatorPosition,
      );
      positionModels.add(positionModel);
      print("index: centerx: ${positionModel.candleCenterX} indexValue: $i");
    }

    return (
      showDatas: showedArray,
      positionModels: positionModels,
      maxPrice: priceResult.maxPrice,
      minPrice: priceResult.minPrice,
      indexBegin: indexResult.$1,
      indexEnd: indexResult.$2,
    );
  }

  /// 计算出当前屏幕中需要渲染的蜡烛图的索引
  static (int, int) _findStartAndEndIndex({
    required double drawMaxWidth,
    required double offset,
    required double crandleWidth,
    required double crandleSpace,
    required int datasCount,
  }) {
    final itemWidth = crandleWidth + crandleSpace;

    // 计算左边界索引
    final leftIndex = (offset / itemWidth).floor();

    // 计算可见范围内能显示多少个蜡烛
    final visibleCount = (drawMaxWidth / itemWidth).ceil() + 2;

    // 计算右边界索引
    final rightIndex = leftIndex + visibleCount;

    // 确保索引在有效范围内
    final startIndex = math.max(0, leftIndex);
    final endIndex = math.min(datasCount - 1, rightIndex);

    print(
      "startIndex: $startIndex, endIndex: $endIndex, offset: $offset, visibleCount: $visibleCount",
    );

    return (math.min(startIndex, endIndex), endIndex);
  }

  static double _computerPositionY({
    required double maxPrice,
    required double minPrice,
    required double value,
    required double totalHeight,
  }) {
    final onePriceHeight = totalHeight / (maxPrice - minPrice);
    return (value - minPrice) * onePriceHeight;
  }

  static ({double maxPrice, double minPrice}) _findMaxAndMinPrice({
    required List<KLineModel> showedArray,
    List<KLineTechnicalIndicatorType> indicatorSelection = const [],
  }) {
    // 检查数组是否为空
    if (showedArray.isEmpty) {
      return (maxPrice: 0.0, minPrice: 0.0);
    }

    // 初始化最大值和最小值为第一个元素的价格
    final firstData = showedArray.first;
    double maxPrice = [
      firstData.klineData.high,
      firstData.klineData.low,
      firstData.klineData.open,
      firstData.klineData.close,
    ].reduce(math.max);

    double minPrice = [
      firstData.klineData.high,
      firstData.klineData.low,
      firstData.klineData.open,
      firstData.klineData.close,
    ].reduce(math.min);

    // 遍历所有蜡烛数据，找到最大和最小价格
    for (final data in showedArray) {
      final currentHigh = data.klineData.high;
      final currentLow = data.klineData.low;
      final currentOpen = data.klineData.open;
      final currentClose = data.klineData.close;

      // 找到当前蜡烛的最高价和最低价
      double currentMaxPrice = [
        currentHigh,
        currentLow,
        currentOpen,
        currentClose,
      ].reduce(math.max);
      double currentMinPrice = [
        currentHigh,
        currentLow,
        currentOpen,
        currentClose,
      ].reduce(math.min);

      // 根据选择的技术指标，将指标值也纳入价格范围计算
      final indicators = data.kLineTechnicalIndicatorsModel;
      if (indicators != null) {
        // MA指标
        if (indicatorSelection.contains(KLineTechnicalIndicatorType.ma)) {
          if (indicators.ma5 != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.ma5!);
            currentMinPrice = math.min(currentMinPrice, indicators.ma5!);
          }
          if (indicators.ma10 != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.ma10!);
            currentMinPrice = math.min(currentMinPrice, indicators.ma10!);
          }
          if (indicators.ma30 != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.ma30!);
            currentMinPrice = math.min(currentMinPrice, indicators.ma30!);
          }
        }

        // EMA指标
        if (indicatorSelection.contains(KLineTechnicalIndicatorType.ema)) {
          if (indicators.ema5 != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.ema5!);
            currentMinPrice = math.min(currentMinPrice, indicators.ema5!);
          }
          if (indicators.ema10 != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.ema10!);
            currentMinPrice = math.min(currentMinPrice, indicators.ema10!);
          }
          if (indicators.ema30 != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.ema30!);
            currentMinPrice = math.min(currentMinPrice, indicators.ema30!);
          }
        }

        // BOLL指标
        if (indicatorSelection.contains(KLineTechnicalIndicatorType.boll)) {
          if (indicators.bollUpper != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.bollUpper!);
          }
          if (indicators.bollLower != null) {
            currentMinPrice = math.min(currentMinPrice, indicators.bollLower!);
          }
          if (indicators.bollMiddle != null) {
            currentMaxPrice = math.max(currentMaxPrice, indicators.bollMiddle!);
            currentMinPrice = math.min(currentMinPrice, indicators.bollMiddle!);
          }
        }
      }

      // 更新全局最大值和最小值
      if (currentMaxPrice > maxPrice) {
        maxPrice = currentMaxPrice;
      }
      if (currentMinPrice < minPrice) {
        minPrice = currentMinPrice;
      }
    }

    return (maxPrice: maxPrice, minPrice: minPrice);
  }
}
