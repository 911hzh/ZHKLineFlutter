import 'package:example/App.dart';
import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  final authToken = await getIt<AuthStoreImpl>().get();
  runApp(App(initialRoute: '/home'));
}
