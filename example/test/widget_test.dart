import 'package:example/App.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/route/RouteConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows login before authentication', (WidgetTester tester) async {
    await tester.pumpWidget(const App(initialRoute: '/login'));

    expect(find.text('Login'), findsWidgets);
  });

  testWidgets('shows module demo entries after login route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(routes: RouteConfig.routes, initialRoute: '/home'),
    );

    expect(find.text('Foundation Kit Demo'), findsOneWidget);
    expect(find.text('Logout Demo'), findsOneWidget);
    expect(find.text('UserStore Demo'), findsOneWidget);
    expect(find.text('CUtil Demo'), findsOneWidget);
    expect(find.text('REST Client Demo'), findsOneWidget);
    expect(find.text('KLine Delegate Demo'), findsOneWidget);
    expect(find.text('Logger Demo'), findsOneWidget);
    expect(find.text('Settings Demo'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Store Demo'), findsOneWidget);
  });
}
