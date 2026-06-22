import 'package:example/base/api/UserApi.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/apiImpl/ApiImplCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ApiImplPage extends StatefulWidget {
  const ApiImplPage({super.key});

  @override
  State<ApiImplPage> createState() => _ApiImplPageState();
}

class _ApiImplPageState extends State<ApiImplPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApiImplCubit(api: getIt<UserApi>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('REST Client Demo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<ApiImplCubit, ApiImplState>(
            builder: (context, state) {
              return ListView(
                children: [
                  const Text('点击 Start 后通过 RestClient 请求远程接口。'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => context.read<ApiImplCubit>().fetchTodo(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                  const SizedBox(height: 12),
                  if (state.isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (state.error != null)
                    _DemoCard(
                      title: '请求失败',
                      children: [Text(state.error.toString())],
                    ),
                  if (state.user != null)
                    _DemoCard(
                      title: 'GET /todos/1',
                      children: [
                        _InfoRow(label: 'id', value: state.user!.id.toString()),
                        _InfoRow(label: 'userId', value: state.user!.userId),
                        _InfoRow(label: 'title', value: state.user!.title),
                        _InfoRow(
                          label: 'completed',
                          value: '${state.user!.completed}',
                        ),
                      ],
                    ),
                  if (!state.hasStarted) const Text('结果会在这里展示。'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
