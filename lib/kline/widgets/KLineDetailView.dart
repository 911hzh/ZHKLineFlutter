import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';

/// K线详细信息显示视图
class KLineDetailView extends StatelessWidget {
  final KLineModel data;
  final bool preferRight;

  const KLineDetailView({Key? key, required this.data, this.preferRight = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = KLineConfig.shared;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: config.crossLineColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.crossLineColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间
          _buildTimeLabel(),
          const SizedBox(height: 0),
          // 开盘价
          _buildLabel('开', data.open),
          const SizedBox(height: 1),
          // 最高价
          _buildLabel('高', data.high),
          const SizedBox(height: 1),
          // 最低价
          _buildLabel('低', data.low),
          const SizedBox(height: 1),
          // 收盘价
          _buildLabel('收', data.close),
          const SizedBox(height: 1),
          // 涨跌额
          _buildChangeAmountLabel(),
          const SizedBox(height: 1),
          // 涨跌幅
          _buildChangeRateLabel(),
          const SizedBox(height: 1),
          // 成交量
          _buildLabel('成交量', data.volume),
        ],
      ),
    );
  }

  /// 构建时间标签
  Widget _buildTimeLabel() {
    // 格式化时间为新加坡时间日期格式
    final date = DateTime.fromMillisecondsSinceEpoch(data.timestamp);
    final formatter = DateFormat('yyyy-MM-dd');
    final timeString = formatter.format(
      date.toUtc().add(const Duration(hours: 8)),
    ); // 新加坡时区 UTC+8

    return SizedBox(
      height: 12,
      child: Text(
        timeString,
        style: const TextStyle(fontSize: 8, color: Colors.black),
      ),
    );
  }

  /// 构建普通标签
  Widget _buildLabel(String title, double value) {
    return Text(
      '$title    ${value.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 8, color: Colors.black),
    );
  }

  /// 构建涨跌额标签
  Widget _buildChangeAmountLabel() {
    final changeAmount = data.changeAmount;
    final changeAmountText =
        changeAmount >= 0
            ? '+${changeAmount.toStringAsFixed(2)}'
            : changeAmount.toStringAsFixed(2);

    return Text(
      '涨跌额    $changeAmountText',
      style: TextStyle(
        fontSize: 8,
        color: changeAmount >= 0 ? Colors.green : Colors.red,
      ),
    );
  }

  /// 构建涨跌幅标签
  Widget _buildChangeRateLabel() {
    final changeRate = data.changeRate * 100;
    final changeRateText =
        changeRate >= 0
            ? '+${changeRate.toStringAsFixed(2)}%'
            : '${changeRate.toStringAsFixed(2)}%';

    return Text(
      '涨跌幅    $changeRateText',
      style: TextStyle(
        fontSize: 8,
        color: changeRate >= 0 ? Colors.green : Colors.red,
      ),
    );
  }
}
