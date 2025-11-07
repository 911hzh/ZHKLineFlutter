import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePeriod.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/api/KlineApi.dart';
import 'package:k_line_flutter/kline/utils/DataUtil.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/KLineView.dart';
import 'package:k_line_flutter/kline/widgets/KLinePeriodView.dart';

/// K线图表页面
/// 对应 Swift 版本的 ChartViewController
class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<KLineModel> _datas = [];
  KLinePeriod _selectedPeriod = KLinePeriod.min15;
  bool _isLoading = false;
  String? _error;

  // 主图指标选择（初始为空）
  List<KLineTechnicalIndicatorType> _mainChartIndicators = [];

  // 副图指标选择（默认显示成交量，提供更好的用户体验）
  List<KLineTechnicalIndicatorType> _secondChartIndicators = [KLineTechnicalIndicatorType.volume];

  @override
  void initState() {
    super.initState();
    _getData();
  }

  /// 获取K线数据
  Future<void> _getData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final klineApi = KlineApi.shared;
      final apiDatas = await klineApi.getBatchKLineData(symbols: ['btcusdt'], period: _selectedPeriod, size: 2000);

      if (apiDatas.containsKey('btcusdt')) {
        final rawData = apiDatas['btcusdt']!;
        final models = DataUtil.toKLineModelsWithIndicators(rawData, _selectedPeriod);

        setState(() {
          _datas = models;
          _isLoading = false;
        });

        print('获取数据成功: ${_datas.length}条');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('获取数据失败: $e');
    }
  }

  /// 周期选择回调
  void _onPeriodSelected(KLinePeriod period) {
    setState(() {
      _selectedPeriod = period;
      _datas = [];
    });
    _getData();
  }

  /// 缩放按钮回调
  void _onScaleButtonTapped() {
    setState(() {
      KLineConfig.scale *= 1.2;
      if (KLineConfig.scale > 3.0) {
        KLineConfig.scale = 0.5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = KLineConfig.shared;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 顶部关闭按钮
              _buildTopBar(),

              const SizedBox(height: 10),

              // 周期选择器
              KLinePeriodView(
                selectedPeriod: _selectedPeriod,
                onPeriodSelected: _onPeriodSelected,
                onMoreButtonTapped: () {
                  print('更多按钮点击');
                },
                onSettingsButtonTapped: () {
                  print('设置按钮点击');
                },
                onZoomButtonTapped: () {
                  print('放大按钮点击');
                },
              ),

              const SizedBox(height: 10),

              // K线图（固定高度，包含内部的指标选择器）
              _buildKLineView(),

              // 缩放测试按钮
              _buildScaleButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建顶部栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('K线图表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: const Text('关闭', style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建K线视图
  Widget _buildKLineView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _getData, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_datas.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return KLineView(
      datas: _datas,
      mainChartIndicatorSelection: _mainChartIndicators,
      secondChartIndicatorSelection: _secondChartIndicators,
      scale: KLineConfig.scale, // 传入缩放比例，让KLineView能够感知变化
    );
  }

  /// 构建缩放按钮
  Widget _buildScaleButton() {
    return GestureDetector(
      onTap: _onScaleButtonTapped,
      child: Container(
        width: 120,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: Text(
          'scale × ${KLineConfig.scale.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
