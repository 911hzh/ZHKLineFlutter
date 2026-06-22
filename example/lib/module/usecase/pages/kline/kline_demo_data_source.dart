// ignore_for_file: file_names

// K 线 Demo 数据源适配器：把 Bloc 状态里的列表转成图表 dataSource。
part of 'KLineDemoPage.dart';

/// 图表 dataSource 适配层，让 package 只通过抽象接口读取 KLineModel。
class _KLineDemoDataSource extends KLineChartDataSource<KLineModel> {
  const _KLineDemoDataSource(this.items);

  final List<KLineModel> items;

  @override
  int numberOfItems(KLineChartContext<KLineModel> context) => items.length;

  @override
  KLineModel itemAt(KLineChartContext<KLineModel> context, int index) {
    return items[index];
  }
}
