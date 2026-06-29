import 'package:example/App.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(App(initialRoute: '/home'));
}
