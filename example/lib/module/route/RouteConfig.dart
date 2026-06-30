import 'package:example/module/usecase/pages/custom_page/custom_controller_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_core_chart_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_grid_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_indicator_entries_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_live_update_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_main_chart_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_overlay_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_secondary_chart_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_selection_view_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_state_builder_page.dart';
import 'package:example/module/usecase/pages/custom_page/custom_theme_layout_page.dart';
import 'package:example/module/usecase/pages/deep_chart/DeepChartDemoPage.dart';
import 'package:example/module/usecase/pages/home/HomePage.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoPage.dart';
import 'package:flutter/material.dart';

class RouteConfig {
  static Map<String, WidgetBuilder> routes = {
    '/home': (context) => const HomePage(),
    KLineDemoPage.routeName: (context) => const KLineDemoPage(),
    DeepChartDemoPage.routeName: (context) => const DeepChartDemoPage(),
    CustomLiveUpdatePage.routeName: (context) => const CustomLiveUpdatePage(),
    CustomThemeLayoutPage.routeName: (context) => const CustomThemeLayoutPage(),
    CustomIndicatorEntriesPage.routeName: (context) =>
        const CustomIndicatorEntriesPage(),
    CustomOverlayPage.routeName: (context) => const CustomOverlayPage(),
    CustomSelectionViewPage.routeName: (context) =>
        const CustomSelectionViewPage(),
    CustomGridPage.routeName: (context) => const CustomGridPage(),
    CustomMainChartPage.routeName: (context) => const CustomMainChartPage(),
    CustomSecondaryChartPage.routeName: (context) =>
        const CustomSecondaryChartPage(),
    CustomControllerPage.routeName: (context) => const CustomControllerPage(),
    CustomStateBuilderPage.routeName: (context) =>
        const CustomStateBuilderPage(),
    CustomCoreChartPage.routeName: (context) => const CustomCoreChartPage(),
  };
}
