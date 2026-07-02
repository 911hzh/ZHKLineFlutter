import 'package:example/module/usecase/pages/custom_page/custom_controller_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_core_chart_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_grid_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_indicator_entries_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_indicator_spec_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_live_update_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_main_chart_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_overlay_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_secondary_chart_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_selection_view_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_state_builder_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_theme_layout_page.dart';
import 'package:example/module/usecase/pages/deep_chart/DeepChartDemoPage.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoPage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePageEntry {
  const HomePageEntry({required this.title, required this.routeName});

  final String title;
  final String routeName;
}

class HomePageState {
  const HomePageState({
    this.title = 'Foundation Kit Demo',
    this.entries = const [
      HomePageEntry(
        title: 'KLine Delegate Demo',
        routeName: KLineDemoPage.routeName,
      ),
      HomePageEntry(title: '深度图 Demo', routeName: DeepChartDemoPage.routeName),
      HomePageEntry(
        title: '实时更新与自定义比较',
        routeName: CustomLiveUpdatePage.routeName,
      ),
      HomePageEntry(
        title: '自定义主题与布局',
        routeName: CustomThemeLayoutPage.routeName,
      ),
      HomePageEntry(
        title: '自定义指标与详情字段',
        routeName: CustomIndicatorEntriesPage.routeName,
      ),
      HomePageEntry(
        title: '动态指标定义',
        routeName: CustomIndicatorSpecPage.routeName,
      ),
      HomePageEntry(title: '自定义覆盖层 UI', routeName: CustomOverlayPage.routeName),
      HomePageEntry(
        title: '自定义长按详情 UI',
        routeName: CustomSelectionViewPage.routeName,
      ),
      HomePageEntry(title: '自定义网格与辅助线', routeName: CustomGridPage.routeName),
      HomePageEntry(title: '自定义主图绘制', routeName: CustomMainChartPage.routeName),
      HomePageEntry(
        title: '自定义副图绘制',
        routeName: CustomSecondaryChartPage.routeName,
      ),
      HomePageEntry(
        title: '外部控制图表状态',
        routeName: CustomControllerPage.routeName,
      ),
      HomePageEntry(
        title: '自定义加载与错误状态',
        routeName: CustomStateBuilderPage.routeName,
      ),
      HomePageEntry(
        title: '完全自定义核心图表',
        routeName: CustomCoreChartPage.routeName,
      ),
    ],
  });

  final String title;
  final List<HomePageEntry> entries;

  HomePageState copyWith({List<HomePageEntry>? entries, String? title}) {
    return HomePageState(
      entries: entries ?? this.entries,
      title: title ?? this.title,
    );
  }
}

class HomePageCubit extends Cubit<HomePageState> {
  HomePageCubit() : super(const HomePageState());
}
