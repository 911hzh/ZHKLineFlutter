import 'package:example/module/route/RouteConfig.dart';
import 'package:example/module/usecase/pages/home/HomePageVM.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home entries mirror registered navigable routes', () {
    final state = const HomePageState();
    final homeRoutes = state.entries.map((entry) => entry.routeName).toList();
    final navigableRoutes = RouteConfig.routes.keys
        .where((route) => route != '/home')
        .toList();

    expect(homeRoutes, navigableRoutes);
  });
}
