import 'package:flutter/material.dart';

import '../../../../core/responsive/screen_layout_builder.dart';
import 'view/login_desktop.dart';
import 'view/login_mobile.dart';
import 'view/login_tablet.dart';


class LoginLayout extends ScreenLayoutBuilder {
  const LoginLayout({super.key});

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