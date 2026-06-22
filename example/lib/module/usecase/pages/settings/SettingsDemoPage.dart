import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/settings/SettingsDemoCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foundation_kit/flutter_foundation_kit.dart';

class SettingsDemoPage extends StatelessWidget {
  const SettingsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsDemoCubit(settingsLoader: getIt<SettingsLoader>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings Demo')),
        body: BlocBuilder<SettingsDemoCubit, SettingsDemoState>(
          builder: (context, state) {
            final settings = state.settings;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('点击 Start 后通过 SettingsLoader 加载配置。'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<SettingsDemoCubit>().load(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(height: 12),
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (state.error != null) Text(state.error.toString()),
                if (!state.hasStarted) const Text('结果会在这里展示。'),
                if (settings != null) ...[
                  _InfoTile(label: 'packageName', value: settings.packageName),
                  _InfoTile(
                    label: 'environment',
                    value: settings.environment.name,
                  ),
                  _InfoTile(label: 'baseUrl', value: settings.baseUrl),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}
