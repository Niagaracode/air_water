import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_providers.dart';

class LoginMobile extends ConsumerStatefulWidget {
  const LoginMobile({super.key});

  @override
  ConsumerState<LoginMobile> createState() => _LoginMobileState();
}

class _LoginMobileState extends ConsumerState<LoginMobile> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    ref.read(authControllerProvider.notifier).login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _usernameController),
            TextField(controller: _passwordController),

            const SizedBox(height: 24),

            // LOGIN BUTTON (always visible)
            ElevatedButton(
              onPressed: state.isLoading ? null : _login,
              child: state.isLoading ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Login'),
            ),

            const SizedBox(height: 12),

            // ERROR MESSAGE
            if (state.hasError)
              Text(
                state.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}