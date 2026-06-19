import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../../../../core/app_theme/app_theme.dart';
import '../../../../core/network/http/api_service.dart';
import '../widgets/login_header.dart';

class ResetPasswordVerifyView extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordVerifyView({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordVerifyView> createState() => _ResetPasswordVerifyViewState();
}

class _ResetPasswordVerifyViewState extends ConsumerState<ResetPasswordVerifyView> {
  bool isVerifying = true;
  String? successMessage;
  String? errorMessage;
  int redirectCountdown = 5;
  Timer? redirectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyToken();
    });
  }

  @override
  void dispose() {
    redirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    if (widget.token.isEmpty) {
      setState(() {
        isVerifying = false;
        errorMessage = 'Invalid password reset token. Please request a new link.';
      });
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post('/forgot-password/verify-link', data: {
        'token': widget.token,
      });

      final data = Map<String, dynamic>.from(response.data);
      setState(() {
        isVerifying = false;
        successMessage = data['message'] ?? 'Password reset verified successfully!';
      });

      // Start redirect countdown
      _startCountdown();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to verify confirmation link. It may be expired or already used.';

      setState(() {
        isVerifying = false;
        errorMessage = message;
      });
    } catch (e) {
      setState(() {
        isVerifying = false;
        errorMessage = 'An unexpected error occurred: $e';
      });
    }
  }

  void _startCountdown() {
    redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (redirectCountdown == 1) {
        timer.cancel();
        context.go('/login');
      } else {
        setState(() {
          redirectCountdown--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    Widget buildContent() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isVerifying) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Verifying your password reset...',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please hold on while we process your request.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (successMessage != null) ...[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Successful!',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  successMessage!,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: primaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Redirecting to Login Page in $redirectCountdown seconds...',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    redirectTimer?.cancel();
                    context.go('/login');
                  },
                  child: const Text('Login Now'),
                ),
              ),
            ] else if (errorMessage != null) ...[
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Failed',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to Login'),
                ),
              ),
            ],
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
                    child: buildContent(),
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
                  child: buildContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
