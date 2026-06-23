import 'package:example/App.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/home/HomePageVM.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows registered module demo entries on home route', (
    tester,
  ) async {
    const state = HomePageState();
    await tester.pumpWidget(const App(initialRoute: '/home'));

    expect(find.text('Foundation Kit Demo'), findsOneWidget);
    for (final entry in state.entries) {
      await tester.scrollUntilVisible(find.text(entry.title), 250);
      expect(find.text(entry.title), findsOneWidget);
    }
  });
}
