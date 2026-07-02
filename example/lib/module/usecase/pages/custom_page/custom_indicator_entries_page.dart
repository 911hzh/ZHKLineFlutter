import 'package:example/base/api/models/KLineModel.dart';
import 'package:example/module/usecase/pages/custom_page/custom_demo_copy.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_demo_shell.dart';
import 'package:example/module/usecase/pages/custom_page/custom_kline_model_adapter.dart';
import 'package:flutter/material.dart';
import 'package:kline_flutter/kline_flutter.dart';

class CustomIndicatorEntriesPage extends StatelessWidget {
  const CustomIndicatorEntriesPage({super.key});

  static const routeName = '/kline/custom/indicator-entries';

  @override
  Widget build(BuildContext context) {
    return const CustomKLineDemoShell(
      copy: CustomDemoCopy(
        title: '自定义指标与详情字段',
        description: '覆盖 KLineDataAdapter 的指标入口，可以重命名指标、调整顺序、改变颜色索引，并扩展长按详情字段。',
        extensionPoint: 'KLineDataAdapter.mainIndicatorEntries / secondaryIndicatorEntries / detailEntries',
        scenario: '适合交易所、券商或量化业务使用自己的指标参数和本地化字段。',
      ),
      adapter: CustomIndicatorEntriesAdapter(),
      initialIndicators: ['ma', 'rsi'],
    );
  }
}

class CustomIndicatorEntriesAdapter extends CustomKLineModelAdapter {
  const CustomIndicatorEntriesAdapter();

  @override
  List<KLineIndicatorEntry> mainIndicatorEntries(KLineModel item, KLineIndicatorSpec<KLineModel> indicator) {
    if (indicator.id == KLineDefaultIndicators.maId) {
      return [
        KLineIndicatorEntry(label: '短线MA5', value: indicatorValue(item, KLineDefaultIndicators.ma5), colorIndex: 0),
        KLineIndicatorEntry(label: '趋势MA30', value: indicatorValue(item, KLineDefaultIndicators.ma30), colorIndex: 2),
      ];
    }
    return super.mainIndicatorEntries(item, indicator);
  }

  @override
  List<KLineIndicatorEntry> secondaryIndicatorEntries(KLineModel item, KLineIndicatorSpec<KLineModel> indicator) {
    if (indicator.id == KLineDefaultIndicators.rsiId) {
      return [
        KLineIndicatorEntry(label: '快RSI', value: indicatorValue(item, KLineDefaultIndicators.rsi6), colorIndex: 3),
        KLineIndicatorEntry(label: '慢RSI', value: indicatorValue(item, KLineDefaultIndicators.rsi24), colorIndex: 1),
      ];
    }
    return super.secondaryIndicatorEntries(item, indicator);
  }

  @override
  List<KLineDetailEntry> detailEntries(KLineModel item) {
    return [
      KLineDetailEntry('交易时段', item.dateString),
      KLineDetailEntry('开盘价', item.open.toStringAsFixed(2)),
      KLineDetailEntry('最高价', item.high.toStringAsFixed(2)),
      KLineDetailEntry('最低价', item.low.toStringAsFixed(2)),
      KLineDetailEntry('收盘价', item.close.toStringAsFixed(2)),
      KLineDetailEntry('涨跌幅', signedPercent(item.changeRate)),
      KLineDetailEntry('成交额', item.amount.toStringAsFixed(2)),
    ];
  }
}
