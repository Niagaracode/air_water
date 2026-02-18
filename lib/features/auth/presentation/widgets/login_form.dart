import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_providers.dart';


class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool obscure = true;
  bool remember = false;

  void _submit() {
    ref.read(authControllerProvider.notifier).login(
      userCtrl.text.trim(),
      passCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome back !',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access your Air Water dashboard',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
      
          _buildLabel('Username*'),
          const SizedBox(height: 8),
          AppTextField(
            controller: userCtrl,
            hint: 'Enter your username',
          ),
          const SizedBox(height: 20),
      
          _buildLabel('Password*'),
          const SizedBox(height: 8),
          AppTextField(
            controller: passCtrl,
            hint: 'Enter your password',
            isPassword: true,
            obscure: obscure,
            onToggle: () =>
                setState(() => obscure = !obscure),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: remember,
                      onChanged: (val) =>
                          setState(() => remember = val ?? false),
                      activeColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember Me',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot Password ?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ),

          if (state.hasError) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Text(
                state.error.toString(),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
    );
  }
}