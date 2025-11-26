import 'package:flutter/material.dart';
import 'package:k_line_flutter/kline/models/KLineModel.dart';
import 'package:k_line_flutter/kline/models/KLinePositionModel.dart';
import 'package:k_line_flutter/kline/models/KLineTechnicalIndicatorType.dart';
import 'package:k_line_flutter/kline/config/KLineConfig.dart';
import 'package:k_line_flutter/kline/utils/KLineCrandleIndexUtil.dart';
import 'package:k_line_flutter/kline/widgets/chart/KLineChartView.dart';
import 'package:k_line_flutter/kline/widgets/chart/KLineMainPainter.dart';
import 'package:k_line_flutter/kline/widgets/KMainIndicatorTextView.dart';
import 'package:k_line_flutter/kline/widgets/KSecondIndicatorTextView.dart';
import 'package:k_line_flutter/kline/widgets/KTechnicalIndicatorControlView.dart';
import 'package:k_line_flutter/kline/widgets/KLineDetailView.dart';

/// K线主视图
class KLineView extends StatefulWidget {
  final List<KLineModel> datas;
  final List<KLineTechnicalIndicatorType> mainChartIndicatorSelection;
  final List<KLineTechnicalIndicatorType> secondChartIndicatorSelection;
  final double scale; // 缩放比例

  const KLineView({
    Key? key,
    required this.datas,
    this.mainChartIndicatorSelection = const [],
    this.secondChartIndicatorSelection = const [],
    required this.scale,
  }) : super(key: key);

  @override
  State<KLineView> createState() => _KLineViewState();
}

class _KLineViewState extends State<KLineView> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // 当前显示的数据和位置
  List<KLineModel> _showDatas = [];
  List<KLinePositionModel> _positionModels = [];
  double _maxPrice = 0.0;
  double _minPrice = 0.0;

  // 手势状态
  KLineModel? _selectedKLineModel;
  bool _shouldShowCrossLine = false;
  Offset _crossLinePoint = Offset.zero;
  Offset _touchScreenPoint = Offset.zero; // 屏幕坐标（用于判断详情视图位置）

  // 缩放状态
  double _baseScale = 1.0;

  // 内部指标选择
  List<KLineTechnicalIndicatorType> _mainChartIndicators = [];
  List<KLineTechnicalIndicatorType> _secondChartIndicators = [];

  @override
  void initState() {
    super.initState();
    _mainChartIndicators = List.from(widget.mainChartIndicatorSelection);
    _secondChartIndicators = List.from(widget.secondChartIndicatorSelection);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDisplayData();
    });
  }

  @override
  void didUpdateWidget(KLineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // // 检测缩放比例变化
    if (oldWidget.scale != widget.scale) {
      print('缩放比例变化: ${oldWidget.scale} -> ${widget.scale}');
      _updateDisplayData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
      // 滚动时隐藏十字线和详情视图（参考 Swift 版本）
      _shouldShowCrossLine = false;
      _selectedKLineModel = null;
      _touchScreenPoint = Offset.zero;
      _updateDisplayData();
    });
  }

  void _updateDisplayData() {
    if (widget.datas.isEmpty || !mounted) return;

    final config = KLineConfig.shared;
    final screenWidth = MediaQuery.of(context).size.width;

    final result = KLineCrandleIndexUtil.computerSize(
      datas: widget.datas,
      drawMaxWidth:
          screenWidth - config.crandleInsets.left - config.crandleInsets.right,
      offset: _scrollOffset,
      crandleWidth: config.candleWidth,
      crandleSpace: config.candleSpace,
      totalHeight:
          config.mainCanvasHeight -
          config.crandleInsets.top -
          config.crandleInsets.bottom,
      indicatorSelection: _mainChartIndicators,
    );

    setState(() {
      _showDatas = result.showDatas;
      _positionModels = result.positionModels;
      _maxPrice = result.maxPrice;
      _minPrice = result.minPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = KLineConfig.shared;
    // KLineView的高度 = getAllHeight (主图+副图)
    // scrollView占据整个KLineView bounds，indicatorControlView覆盖在底部
    final viewHeight = config.getAllHeight(_secondChartIndicators);
    final indicatorControlHeight = config.indicatorTypeControlHeight;

    // 计算内容宽度
    final contentWidth =
        (config.candleWidth + config.candleSpace) * widget.datas.length +
        config.crandleInsets.left +
        config.crandleInsets.right +
        config.crossLineWidth * 2;

    return SizedBox(
      width: double.infinity,
      height: viewHeight,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        // onTapDown: _onTapDown,
        onLongPressStart: _onLongPressStart,
        onLongPressMoveUpdate: _onLongPressMoveUpdate,
        onLongPressEnd: _onLongPressEnd,
        onTapUp: _onTapUp,
        child: Stack(
          children: [
            // 固定的网格线层（不随滚动移动）- 占据整个viewHeight
            _buildGridLayer(),

            // 可滚动的内容层（蜡烛图和指标）- 占据整个viewHeight
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentWidth,
                height: viewHeight,
                child: KLineChartView(
                  datas: _showDatas,
                  positionDatas: _positionModels,
                  maxPrice: _maxPrice,
                  minPrice: _minPrice,
                  mainChartIndicatorSelection: _mainChartIndicators,
                  selectIndicatorTypes: _secondChartIndicators,
                  // 如果没有选中数据，使用第一条可见数据（类似 Swift 版本）
                  selectedKLineModel:
                      _selectedKLineModel ??
                      (_showDatas.isNotEmpty ? _showDatas.first : null),
                  crossLinePoint: _crossLinePoint,
                  showCrossLine: _shouldShowCrossLine,
                  scrollOffset: _scrollOffset,
                ),
              ),
            ),

            // 主图指标数值显示层（固定不随滚动移动）
            _buildMainIndicatorTextLayer(),

            // 副图指标数值显示层（固定不随滚动移动）
            _buildSecondIndicatorTextLayer(),

            // 技术指标选择器（覆盖在底部30px）
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                child: KTechnicalIndicatorControlView(
                  initialSelection: [
                    ..._mainChartIndicators,
                    ..._secondChartIndicators,
                  ],
                  onIndicatorSelectionChanged: _onIndicatorSelectionChanged,
                ),
              ),
            ),

            // K线详细信息视图（当长按时显示）
            if (_shouldShowCrossLine && _selectedKLineModel != null)
              _buildDetailView(),
          ],
        ),
      ),
    );
  }

  /// 指标选择变化回调
  void _onIndicatorSelectionChanged(List<KLineTechnicalIndicatorType> types) {
    setState(() {
      final mainIndicators = <KLineTechnicalIndicatorType>[];
      final secondIndicators = <KLineTechnicalIndicatorType>[];

      for (var type in types) {
        if (type.isMainType) {
          mainIndicators.add(type);
        } else if (type.isSecondType) {
          secondIndicators.add(type);
        }
      }

      _mainChartIndicators = mainIndicators;
      _secondChartIndicators = secondIndicators;

      print('指标选择更新: 主图=$_mainChartIndicators, 副图=$_secondChartIndicators');
      _updateDisplayData();
    });
  }

  /// 构建固定的网格线层
  Widget _buildGridLayer() {
    final config = KLineConfig.shared;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // 主图网格
            Positioned(
              left: config.chartViewPadding.left,
              top: 0,
              right: config.chartViewPadding.right,
              height: config.mainCanvasHeight,
              child: CustomPaint(
                painter: CrossGridPainter(
                  topHeight: config.crandleInsets.top,
                  bottomHeight: config.crandleInsets.bottom,
                  horLineCount: config.crossHorCount,
                  verticalLineCount: config.crossVerticalCount,
                  lineWidth: config.crossLineWidth,
                  lineColor: config.crossLineColor,
                  horLineTexts: _createHorShowTexts(),
                  verticalLineTexts: _createVerticalShowTexts(),
                ),
              ),
            ),

            // 副图网格
            if (_secondChartIndicators.isNotEmpty)
              Positioned(
                left: config.chartViewPadding.left,
                top: config.mainCanvasHeight,
                right: config.chartViewPadding.right,
                height: config.getSecoendHeight(_secondChartIndicators),
                child: CustomPaint(
                  painter: CrossGridPainter(
                    topHeight: 0,
                    bottomHeight: 0,
                    horLineCount: 2,
                    verticalLineCount: config.crossVerticalCount,
                    lineWidth: config.crossLineWidth,
                    lineColor: config.crossLineColor,
                    horLineTexts: [],
                    verticalLineTexts: [],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建主图指标文本层（固定不滚动）
  Widget _buildMainIndicatorTextLayer() {
    final config = KLineConfig.shared;
    final selectedModel =
        _selectedKLineModel ??
        (_showDatas.isNotEmpty ? _showDatas.first : null);

    if (selectedModel == null || _mainChartIndicators.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: config.chartViewPadding.left + 10,
      top: 5,
      child: IgnorePointer(
        child: KMainIndicatorTextView(
          selectedKLineModel: selectedModel,
          indicatorSelection: _mainChartIndicators,
        ),
      ),
    );
  }

  /// 构建副图指标文本层（固定不滚动）
  /// 参考 Swift 版本：每个副图指标的标签显示在各自的区域
  Widget _buildSecondIndicatorTextLayer() {
    final config = KLineConfig.shared;
    final selectedModel =
        _selectedKLineModel ??
        (_showDatas.isNotEmpty ? _showDatas.first : null);

    if (selectedModel == null || _secondChartIndicators.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: KSecondIndicatorTextView(
        selectedKLineModel: selectedModel,
        indicatorSelection: _secondChartIndicators,
        baseTopOffset: config.mainCanvasHeight,
      ),
    );
  }

  /// 创建横向文本
  List<String> _createHorShowTexts() {
    List<String> array = [];
    final itemPrice = (_maxPrice - _minPrice) / 2;

    for (int i = 0; i < KLineConfig.shared.crossHorCount; i++) {
      double number = i == 0 ? _minPrice : (_minPrice + itemPrice);
      number = (i == KLineConfig.shared.crossHorCount - 1) ? _maxPrice : number;
      array.add(number.toStringAsFixed(2));
    }

    return array;
  }

  /// 创建纵向文本
  List<String> _createVerticalShowTexts() {
    List<String> array = [];
    final lineCount = KLineConfig.shared.crossVerticalCount;

    for (int i = 0; i < lineCount; i++) {
      if (i < _showDatas.length) {
        array.add(_showDatas[i].dateString);
      } else {
        array.add('');
      }
    }

    return array;
  }

  // 手势处理
  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = KLineConfig.scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      setState(() {
        final newScale = (_baseScale * details.scale).clamp(0.5, 3.0);
        KLineConfig.scale = newScale;
        _updateDisplayData();
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // 缩放结束
  }

  void _onTapUp(TapUpDetails details) {
    _handleLongPress(details.localPosition);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _handleLongPress(details.localPosition);
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _handleLongPress(details.localPosition);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    // 保持十字线显示
  }

  void _handleLongPress(Offset localPosition) {
    if (_positionModels.isEmpty) return;

    // 找到最接近的蜡烛
    final adjustedX = localPosition.dx + _scrollOffset;

    // 简单查找最近的蜡烛
    double minDistance = double.infinity;
    int selectedIndex = -1;

    for (int i = 0; i < _positionModels.length; i++) {
      final distance = (adjustedX - _positionModels[i].candleCenterX).abs();
      if (distance < minDistance) {
        minDistance = distance;
        selectedIndex = i;
      }
    }

    if (selectedIndex >= 0 && selectedIndex < _showDatas.length) {
      setState(() {
        _selectedKLineModel = _showDatas[selectedIndex];
        _shouldShowCrossLine = true;
        _crossLinePoint = Offset(adjustedX, localPosition.dy);
        _touchScreenPoint = localPosition; // 保存屏幕坐标
      });
    }
  }

  /// 构建K线详细信息视图
  /// 参考 Swift 版本：固定显示在左上角或右上角
  Widget _buildDetailView() {
    if (_selectedKLineModel == null) return const SizedBox.shrink();

    const margin = 16.0;

    // 判断详情视图应该显示在左侧还是右侧
    // 如果触摸点在屏幕左半部分，显示在右侧；否则显示在左侧
    final screenWidth = MediaQuery.of(context).size.width;
    final preferRight = _touchScreenPoint.dx < screenWidth / 2;

    return Positioned(
      left: preferRight ? null : margin,
      right: preferRight ? margin : null,
      top: margin,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _shouldShowCrossLine ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: KLineDetailView(
            data: _selectedKLineModel!,
            preferRight: preferRight,
          ),
        ),
      ),
    );
  }
}
