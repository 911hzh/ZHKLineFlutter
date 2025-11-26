import 'package:flutter/material.dart';
import 'package:k_line_flutter/page/CustomPaintPage.dart';
import 'package:k_line_flutter/page/Mixinpage.dart';

final Map<String, WidgetBuilder> router = {
  '/mixin': (context) => Mixinpage(),
  '/customPaint': (context) => CustomPaintPage(),
};
