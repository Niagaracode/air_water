import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_config.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key, required this.isNarrow});
  final bool isNarrow;

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
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Air Water logo
          Center(
            child: SvgPicture.asset(
              AppConfig.current.companySmallLogoPath,
              width: 60,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Column(
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
                  'Sign in to access your account and manage your devices.',
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
            onToggle: () => setState(() => obscure = !obscure),
          ),

          const SizedBox(height: 12),

          // Remember me row
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Remember Me'),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot Password ?'),
              ),
            ],
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: widget.isNarrow ? 60 : 54,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
          ),

          if (state.hasError) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                state.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Powered by
          Align(
            alignment: Alignment.centerRight,
            child: _buildPoweredBy(),
          ),

          const SizedBox(height: 16),
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

  Widget _buildPoweredBy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POWERED BY',
          style: GoogleFonts.outfit(
            fontSize: 10,
            letterSpacing: 0.8,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        SvgPicture.asset(
          AppConfig.current.companyLogoPath,
          height: 25,
        ),
      ],
    );
  }
}