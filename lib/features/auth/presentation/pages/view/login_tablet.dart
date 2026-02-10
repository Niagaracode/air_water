import 'package:flutter/material.dart';
import 'login_mobile.dart';

class LoginTablet extends StatelessWidget {
  const LoginTablet({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, we use the premium mobile layout for tablets
    // but we can wrap it in a Center and ConstrainedBox for better large-screen appearance
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: const LoginMobile(),
      ),
    );
  }
}
