import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/api/KlineApi.dart';
import 'package:k_line_flutter/kline/utils/DataUtil.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/KLineView.dart';

/// K线演示页面
class KLineDemoPage extends StatefulWidget {
  const KLineDemoPage({Key? key}) : super(key: key);

  @override
  State<KLineDemoPage> createState() => _KLineDemoPageState();
}

class _KLineDemoPageState extends State<KLineDemoPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _klineModels = [];

  // 选中的指标
  final List<KLineTechnicalIndicatorType> _mainChartIndicators = [KLineTechnicalIndicatorType.ma];
  final List<KLineTechnicalIndicatorType> _secondChartIndicators = [KLineTechnicalIndicatorType.volume];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取K线数据
      final klineApi = KlineApi.shared;
      final datas = await klineApi.getKLineModels(symbol: 'btcusdt', period: KLinePeriod.day1, size: 200);

      // 计算技术指标
      final models = DataUtil.toKLineModelsWithIndicators(datas, KLinePeriod.day1);

      setState(() {
        _klineModels = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('K线图演示'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_klineModels.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return Column(
      children: [
        // 指标选择器
        _buildIndicatorSelector(),

        // K线图
        Expanded(
          child: SingleChildScrollView(
            child: KLineView(
              datas: _klineModels.cast(),
              mainChartIndicatorSelection: _mainChartIndicators,
              secondChartIndicatorSelection: _secondChartIndicators,
              scale: KLineConfig.scale, // 传入缩放比例
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('主图指标:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              _buildIndicatorChip('MA', KLineTechnicalIndicatorType.ma, true),
              _buildIndicatorChip('EMA', KLineTechnicalIndicatorType.ema, true),
              _buildIndicatorChip('BOLL', KLineTechnicalIndicatorType.boll, true),
            ],
          ),
          const SizedBox(height: 8),
          const Text('副图指标:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              _buildIndicatorChip('VOL', KLineTechnicalIndicatorType.volume, false),
              _buildIndicatorChip('MACD', KLineTechnicalIndicatorType.macd, false),
              _buildIndicatorChip('KDJ', KLineTechnicalIndicatorType.kdj, false),
              _buildIndicatorChip('RSI', KLineTechnicalIndicatorType.rsi, false),
              _buildIndicatorChip('WR', KLineTechnicalIndicatorType.wr, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorChip(String label, KLineTechnicalIndicatorType type, bool isMainChart) {
    final indicators = isMainChart ? _mainChartIndicators : _secondChartIndicators;
    final isSelected = indicators.contains(type);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            indicators.add(type);
          } else {
            indicators.remove(type);
          }
        });
      },
    );
  }
}
