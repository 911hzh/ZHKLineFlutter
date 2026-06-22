import 'package:example/module/usecase/pages/logger/LoggerCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoggerPage extends StatelessWidget {
  const LoggerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoggerCubit(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Logger Demo')),
        body: BlocBuilder<LoggerCubit, LoggerState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Page 只负责展示，Cubit 负责调用 Logger API。'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.read<LoggerCubit>().writeLogs(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<LoggerCubit>().configurePathLogOutput(),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('配置 path 文件日志'),
                ),
                const SizedBox(height: 12),
                if (!state.hasStarted)
                  const Text('点击 Start 后会写入控制台日志，并展示执行步骤。'),
                if (state.logFilePath != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('当前文件日志路径'),
                      subtitle: Text(state.logFilePath!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '使用方式：先通过 LoggerConfiguration.file 配置 tag 和 filePath，'
                    '再用 LoggerFactory.current.getLogger([tag]) 写入日志。',
                  ),
                ],
                for (final message in state.messages)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.terminal),
                      title: Text(message),
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
