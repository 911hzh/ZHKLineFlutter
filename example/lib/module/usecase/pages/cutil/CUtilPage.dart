import 'package:example/module/usecase/pages/cutil/CUtilCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CUtilPage extends StatelessWidget {
  const CUtilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CUtilCubit(),
      child: Scaffold(
        appBar: AppBar(title: const Text('CUtil Demo')),
        body: BlocBuilder<CUtilCubit, CUtilState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('点击 Start 后执行 JsonUtil、Lazyload 和 Polling 示例。'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.read<CUtilCubit>().runDemo(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(height: 12),
                if (state.hasStarted) ...[
                  _DemoTile(
                    title: 'JsonUtil.pretty()',
                    value: state.prettyJson,
                  ),
                  _DemoTile(title: 'Lazyload.get()', value: state.lazyValue),
                  _DemoTile(
                    title: 'Runtime generated id',
                    value: '${state.generatedId}',
                  ),
                  _DemoTile(
                    title: 'Polling callback',
                    value: state.pollingValues.join(', '),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value.isEmpty ? 'loading...' : value),
      ),
    );
  }
}
