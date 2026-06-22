import 'package:example/module/getIt/Injection.dart';
import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:example/base/store/settings/SettingsStore.dart';
import 'package:example/module/usecase/pages/store/StoreDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StoreDemoPage extends StatelessWidget {
  const StoreDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StoreDemoCubit(
        settingsStore: getIt<SettingsStore>(),
        authStore: getIt<AuthStoreImpl>(),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Store Demo')),
        body: BlocBuilder<StoreDemoCubit, StoreDemoState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('点击 Start 后执行 SettingsStore 和 AuthStore 示例。'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<StoreDemoCubit>().load(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(height: 12),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (state.error != null) Text(state.error.toString()),
                if (!state.hasStarted) const Text('结果会在这里展示。'),
                if (state.settings != null)
                  Card(
                    child: ListTile(
                      title: const Text('SettingsStore result'),
                      subtitle: Text(state.settings!.toJson().toString()),
                    ),
                  ),
                if (state.authState != null)
                  Card(
                    child: ListTile(
                      title: const Text('AuthStore result'),
                      subtitle: Text(state.authState!.toJson().toString()),
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
