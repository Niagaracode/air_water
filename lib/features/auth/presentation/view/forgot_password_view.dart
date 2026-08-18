import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/network/http/api_service.dart';
import '../widgets/login_header.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  String selectedMethod = 'email'; // 'email' or 'sms'
  bool obscurePass = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;
  String? simulatedLink;

  Future<void> _submit() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      simulatedLink = null;
    });

    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();
    final confirmPassword = confirmPassCtrl.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'All fields are required';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        isLoading = false;
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/forgot-password/request', data: {
        'username': username,
        'password': password,
        'confirm_password': confirmPassword,
        'method': selectedMethod,
      });

      final data = Map<String, dynamic>.from(response.data);
      setState(() {
        isLoading = false;
        successMessage = data['message'] ?? 'Password reset link sent successfully!';
        simulatedLink = data['simulated_link'];
      });
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Network error. Please try again.';

      setState(() {
        isLoading = false;
        errorMessage = message;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    Widget buildFormContent() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Forgot Password',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter details to request password reset',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildLabel('Username*'),
            const SizedBox(height: 8),
            AppTextField(
              controller: userCtrl,
              hint: 'Enter your username',
            ),
            const SizedBox(height: 16),

            _buildLabel('New Password*'),
            const SizedBox(height: 8),
            AppTextField(
              controller: passCtrl,
              hint: 'Enter new password',
              isPassword: true,
              obscure: obscurePass,
              onToggle: () => setState(() => obscurePass = !obscurePass),
            ),
            const SizedBox(height: 16),

            _buildLabel('Confirm Password*'),
            const SizedBox(height: 8),
            AppTextField(
              controller: confirmPassCtrl,
              hint: 'Confirm new password',
              isPassword: true,
              obscure: obscureConfirm,
              onToggle: () => setState(() => obscureConfirm = !obscureConfirm),
            ),
            const SizedBox(height: 20),

            _buildLabel('Reset Notification Method*'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildRadioOption('Email', 'email'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRadioOption('SMS', 'sms'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (successMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  successMessage!,
                  style: GoogleFonts.outfit(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Reset Password'),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isWide) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            Expanded(
              child: Container(
                color: theme.primaryColor,
                child: const LoginHeader(isNarrow: false),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: buildFormContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            color: theme.primaryColor,
            child: const LoginHeader(isNarrow: true),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: buildFormContent(),
                ),
              ),
            ),
          ),
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

  Widget _buildRadioOption(String title, String value) {
    final isSelected = selectedMethod == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => selectedMethod = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.primaryColor : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme.primaryColor : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? theme.primaryColor : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
