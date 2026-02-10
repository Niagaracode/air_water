import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

class LoginMobile extends ConsumerStatefulWidget {
  const LoginMobile({super.key});

  @override
  ConsumerState<LoginMobile> createState() => _LoginMobileState();
}

class _LoginMobileState extends ConsumerState<LoginMobile> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: theme.primaryColor,
              child: const LoginHeader(isNarrow: true),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 40),
                  child: const LoginForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}