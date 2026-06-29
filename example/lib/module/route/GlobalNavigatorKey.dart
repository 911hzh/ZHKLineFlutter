import 'package:flutter/material.dart';

final globalNavigatorKey = GlobalKey<NavigatorState>();

extension NavigatorExtension on BuildContext {
  void pushNamed(String name) {
    Navigator.of(this).pushNamed(name);
  }

  void pushReplacementNamed(String name) {
    Navigator.of(this).pushReplacementNamed(name);
  }
}
