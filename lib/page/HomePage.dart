import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/customPaint');
            },
            child: Text('CustomPaint'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/mixin');
            },
            child: Text('Mixin'),
          ),
          Text('HomePage'),
        ],
      ),
    );
  }
}
