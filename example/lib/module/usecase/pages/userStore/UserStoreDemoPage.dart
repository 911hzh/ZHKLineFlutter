import 'package:example/base/store/user/UserStoreImpl.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/userStore/UserStoreDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserStoreDemoPage extends StatelessWidget {
  const UserStoreDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserStoreDemoCubit(userStore: getIt<UserStoreImpl>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('UserStore Demo')),
        body: BlocBuilder<UserStoreDemoCubit, UserStoreDemoState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '点击 Start 后，UserStore 会从 AuthStore 获取 userId，并按 userId 读取/缓存用户资料。',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<UserStoreDemoCubit>().start(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(height: 12),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (state.error != null) Text(state.error.toString()),
                if (!state.hasStarted) const Text('结果会在这里展示。'),
                if (state.userState != null)
                  Card(
                    child: ListTile(
                      title: const Text('UserStore result'),
                      subtitle: Text(state.userState!.toJson().toString()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
