import 'package:example/module/usecase/pages/apiImpl/ApiImplPage.dart';
import 'package:example/module/usecase/pages/cutil/CUtilPage.dart';
import 'package:example/module/usecase/pages/home/HomePage.dart';
import 'package:example/module/usecase/pages/kline/KLineDemoPage.dart';
import 'package:example/module/usecase/pages/login/LoginPage.dart';
import 'package:example/module/usecase/pages/logout/LogoutPage.dart';
import 'package:example/module/usecase/pages/logger/LoggerPage.dart';
import 'package:example/module/usecase/pages/settings/SettingsDemoPage.dart';
import 'package:example/module/usecase/pages/store/StoreDemoPage.dart';
import 'package:example/module/usecase/pages/userStore/UserStoreDemoPage.dart';
import 'package:flutter/material.dart';

class RouteConfig {
  static Map<String, WidgetBuilder> routes = {
    "/login": (context) => const LoginPage(),
    "/logout": (context) => const LogoutPage(),
    "/home": (context) => const HomePage(),
    "/cutil": (context) => const CUtilPage(),
    "/apiImpl": (context) => const ApiImplPage(),
    "/logger": (context) => const LoggerPage(),
    "/kline": (context) => const KLineDemoPage(),
    "/settings": (context) => const SettingsDemoPage(),
    "/store": (context) => const StoreDemoPage(),
    "/userStore": (context) => const UserStoreDemoPage(),
  };
}
