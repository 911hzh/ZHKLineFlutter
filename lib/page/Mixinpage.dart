import 'dart:async';

import 'package:flutter/material.dart';
import 'package:k_line_flutter/GetItConfiguation.dart';
import 'package:k_line_flutter/base/TestStore.dart';

mixin MixinpageMixin {
  String a = 'a';
  void onTap() {
    print('onTap');
  }

  void test();
}

extension AExtension on A {}

mixin MixinpageMixin2 {
  void onTap() {
    print('onTap2');
  }
}

abstract class B {
  void onTap() {
    print('B onTap');
  }
}

class A extends B with MixinpageMixin, MixinpageMixin2 {
  String b = 'b';
  final listen = StreamController<String>();
  A(this.b);
  // void onTap() {
  //   print('A onTap');
  // }

  void test() {
    listen.add('test');
    print('A test');
  }
}

class Mixinpage extends StatelessWidget {
  Mixinpage({super.key});
  final A a = A('a');
  final name = getIt.get<TestStore>().name;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  print(name);
                  a.onTap();
                },
                child: Text('A onTap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
