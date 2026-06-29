import 'dart:math';

import 'package:example/module/usecase/pages/home/HomePageVM.dart';
import 'package:example/module/route/GlobalNavigatorKey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomePageCubit(),
      child: BlocBuilder<HomePageCubit, HomePageState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(state.title)),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final item = state.entries[index];
                final random = Random(index);
                final color = Color.fromARGB(
                  255,
                  120 + random.nextInt(100),
                  120 + random.nextInt(100),
                  120 + random.nextInt(100),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        foregroundColor: color,
                        child: const Icon(Icons.widgets_rounded),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onTap: () {
                        context.pushNamed(item.routeName);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
