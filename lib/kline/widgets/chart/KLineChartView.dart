import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/widgets/chart/KLineMainPainter.dart';
import 'package:k_line_flutter/kline/widgets/chart/KLineSecondLayerPainter.dart';

/// K线图表视图
class KLineChartView extends StatefulWidget {
  final List<KLineModel> datas;
  final List<KLinePositionModel> positionDatas;
  final double maxPrice;
  final double minPrice;
  final List<KLineTechnicalIndicatorType> mainChartIndicatorSelection;
  final List<KLineTechnicalIndicatorType> selectIndicatorTypes;
  final KLineModel? selectedKLineModel;
  final Offset? crossLinePoint;
  final bool showCrossLine;
  final double scrollOffset;

  const KLineChartView({
    Key? key,
    required this.datas,
    required this.positionDatas,
    required this.maxPrice,
    required this.minPrice,
    this.mainChartIndicatorSelection = const [],
    this.selectIndicatorTypes = const [],
    this.selectedKLineModel,
    this.crossLinePoint,
    this.showCrossLine = false,
    this.scrollOffset = 0.0,
  }) : super(key: key);

  @override
  State<KLineChartView> createState() => _KLineChartViewState();
}

class _KLineChartViewState extends State<KLineChartView> {
  @override
  Widget build(BuildContext context) {
    final config = KLineConfig.shared;

    return SizedBox(
      width: double.infinity,
      height: config.getAllHeight(widget.selectIndicatorTypes),
      child: Stack(
        children: [
          // 主图区域
          _buildMainChart(),

          // 副图区域
          if (widget.selectIndicatorTypes.isNotEmpty) _buildSecondChart(),

          // 十字线
          if (widget.showCrossLine && widget.crossLinePoint != null)
            _buildCrossLine(widget.scrollOffset),
        ],
      ),
    );
  }

  /// 构建主图
  Widget _buildMainChart() {
    final config = KLineConfig.shared;

    return Positioned(
      left: config.chartViewPadding.left,
      top: 0,
      right: config.chartViewPadding.right,
      height: config.mainCanvasHeight,
      child: Padding(
        padding: config.crandleInsets,
        child: CustomPaint(
          size: Size.infinite,
          painter: KLineMainPainter(
            datas: widget.datas,
            positionDatas: widget.positionDatas,
            maxPrice: widget.maxPrice,
            minPrice: widget.minPrice,
            mainChartIndicatorSelection: widget.mainChartIndicatorSelection,
          ),
        ),
      ),
    );
  }

  /// 构建副图
  Widget _buildSecondChart() {
    final config = KLineConfig.shared;
    final secondHeight = config.getSecoendHeight(widget.selectIndicatorTypes);

    return Positioned(
      left: config.chartViewPadding.left,
      top: config.mainCanvasHeight,
      right: config.chartViewPadding.right,
      height: secondHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: KLineSecondLayerPainter(
          klineModels: widget.datas,
          positionModels: widget.positionDatas,
          needDrawTypes: widget.selectIndicatorTypes,
          itemHeight: config.crossItemHeight,
          selectedKLineModel: widget.selectedKLineModel,
        ),
      ),
    );
  }

  /// 构建十字线
  Widget _buildCrossLine(double scrollOffset) {
    final config = KLineConfig.shared;
    final secondLayerHeight = config.getSecoendHeight(
      widget.selectIndicatorTypes,
    );

    return Positioned(
      left: config.chartViewPadding.left,
      top: 0,
      right: 0,
      height: config.mainCanvasHeight + secondLayerHeight,
      child: CustomPaint(
        size: Size.infinite,
        painter: CrossLinePainter(
          point: widget.crossLinePoint!,
          containerSize: Size(
            MediaQuery.of(context).size.width,
            config.mainCanvasHeight,
          ),
          verticalLineTopY: config.crandleInsets.top,
          verticalLineBottomY: config.mainCanvasHeight + secondLayerHeight,
          horizontalLineLeftX: config.crandleInsets.left,
          horizontalLineRightX:
              MediaQuery.of(context).size.width - config.crandleInsets.right,
          crossLineColor: config.crossLineColor,
          crossLineWidth: config.crossLineWidth,
          selectedKLineModel: widget.selectedKLineModel,
          bottomHeight: config.crandleInsets.bottom,
        ),
      ),
    );
  }
}
