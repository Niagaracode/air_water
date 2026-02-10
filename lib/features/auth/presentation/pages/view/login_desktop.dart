import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/login_form.dart';
import '../../widgets/login_header.dart';

class LoginDesktop extends ConsumerStatefulWidget {
  const LoginDesktop({super.key});

  @override
  ConsumerState<LoginDesktop> createState() => _LoginDesktopState();
}

class _LoginDesktopState extends ConsumerState<LoginDesktop> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 40),
                  child: const LoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
