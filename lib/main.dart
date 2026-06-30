import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Flutter K线图', home: MarketPage());
  }
}

/// 用户自己的行情页面。
///
/// 在业务页面中，只需要把 K 线数据数组和对应 adapter 传给 [KLineWidget]。
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('K 线图最小接入')),
      body: const Padding(
        padding: EdgeInsets.all(12),
        child: KLineWidget<MyCandle>(
          dataSource: _candles,
          adapter: MyCandleAdapter(),
          initialIndicators: ['volume'],
        ),
      ),
    );
  }
}

/// 用户自己的 K 线数据类。
///
/// 该类可以来自接口、数据库或本地计算结果，不需要继承 package 内部 model。
class MyCandle {
  const MyCandle({
    required this.timestampMs,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timeLabel,
  });

  final int timestampMs;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final String timeLabel;
}

/// 将业务数据转换成默认 K 线 UI 可识别的字段。
class MyCandleAdapter extends KLineDataAdapter<MyCandle> {
  const MyCandleAdapter();

  @override
  double open(MyCandle item) => item.open;

  @override
  double high(MyCandle item) => item.high;

  @override
  double low(MyCandle item) => item.low;

  @override
  double close(MyCandle item) => item.close;

  @override
  double volume(MyCandle item) => item.volume;

  @override
  String dateLabel(MyCandle item) => item.timeLabel;
}

const _candles = [
  MyCandle(
    timestampMs: 1719649800000,
    open: 100,
    high: 108,
    low: 98,
    close: 106,
    volume: 1200,
    timeLabel: '09:30',
  ),
  MyCandle(
    timestampMs: 1719651600000,
    open: 106,
    high: 112,
    low: 104,
    close: 110,
    volume: 1680,
    timeLabel: '10:00',
  ),
  MyCandle(
    timestampMs: 1719653400000,
    open: 110,
    high: 111,
    low: 101,
    close: 103,
    volume: 980,
    timeLabel: '10:30',
  ),
  MyCandle(
    timestampMs: 1719655200000,
    open: 103,
    high: 109,
    low: 102,
    close: 108,
    volume: 1320,
    timeLabel: '11:00',
  ),
  MyCandle(
    timestampMs: 1719657000000,
    open: 108,
    high: 116,
    low: 107,
    close: 114,
    volume: 1510,
    timeLabel: '11:30',
  ),
];
