import 'package:example/base/api/UserApi.dart';
import 'package:example/base/store/auth/AuthStoreImpl.dart';
import 'package:example/module/getIt/Injection.dart';
import 'package:example/module/usecase/pages/login/LoginCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController(text: 'demo');
  final _passwordController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(
        userApi: getIt<UserApi>(),
        authStore: getIt<AuthStoreImpl>(),
      ),
      child: BlocListener<LoginCubit, LoginState>(
        listenWhen: (previous, current) =>
            previous.isSuccess != current.isSuccess,
        listener: (context, state) {
          if (state.isSuccess) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Login')),
          body: BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('登录成功后会写入 AuthStore，然后进入首页。'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => context.read<LoginCubit>().login(
                            username: _usernameController.text,
                            password: _passwordController.text,
                          ),
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
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
