import 'package:flutter/cupertino.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo.png', width: size, height: size);
  }
}