import 'package:flutter/material.dart';
import '../../core/responsive/screen_layout_builder.dart';
import '../../core/user_config/user_role.dart';
import 'others_layout_middle.dart';
import 'others_layout_narrow.dart';
import 'others_layout_wide.dart';

class OthersLayout extends ScreenLayoutBuilder {

  final UserRole userRole;

  const OthersLayout({
    super.key,
    required super.child,
    required this.userRole,
  });

  @override
  Widget buildNarrow(BuildContext context) {
    return OthersLayoutNarrow(
      userRole: userRole,
      child: child,
    );
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return OthersLayoutMiddle(
      userRole: userRole,
      child: child,
    );
  }

  @override
  Widget buildWide(BuildContext context) {
    return OthersLayoutWide(
      userRole: userRole,
      child: child,
    );
  }
}