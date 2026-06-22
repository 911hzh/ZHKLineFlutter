import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/logout/LogoutCubit.dart';
import 'package:example/module/route/GlobalNavigatorKey.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LogoutCubit(authStore: getIt<AuthStoreImpl>()),
      child: BlocListener<LogoutCubit, LogoutState>(
        listenWhen: (previous, current) =>
            previous.isSuccess != current.isSuccess,
        listener: (context, state) {
          if (state.isSuccess) {
            Navigator.of(context).popUntil(ModalRoute.withName('/home'));
            context.pushReplacementNamed('/login');
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Logout Demo')),
          body: BlocBuilder<LogoutCubit, LogoutState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('点击按钮后会清空 AuthStore，并返回登录页。'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => context.read<LogoutCubit>().logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                  if (state.isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
