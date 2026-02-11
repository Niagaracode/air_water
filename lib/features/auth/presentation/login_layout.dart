import 'package:air_water/features/auth/presentation/view/login_desktop.dart';
import 'package:air_water/features/auth/presentation/view/login_mobile.dart';
import 'package:air_water/features/auth/presentation/view/login_tablet.dart';
import 'package:flutter/material.dart';
import '../../../core/responsive/screen_layout_builder.dart';


class LoginLayout extends ScreenLayoutBuilder {
  const LoginLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return const LoginMobile();
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return const LoginTablet();
  }

  @override
  Widget buildWide(BuildContext context) {
    return const LoginDesktop();
  }
}