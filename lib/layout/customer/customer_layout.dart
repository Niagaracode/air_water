import 'package:air_water/layout/customer/customer_layout_middle.dart';
import 'package:air_water/layout/customer/customer_layout_narrow.dart';
import 'package:air_water/layout/customer/customer_layout_wide.dart';
import 'package:flutter/material.dart';
import '../../core/responsive/screen_layout_builder.dart';
import '../../core/user_config/user_role.dart';


class CustomerLayout extends ScreenLayoutBuilder {

  final UserRole userRole;

  const CustomerLayout({
    super.key,
    required super.child,
    required this.userRole,
  });

  @override
  Widget buildNarrow(BuildContext context) {
    return CustomerLayoutNarrow(
      userRole: userRole,
      child: child,
    );
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return CustomerLayoutMiddle(
      userRole: userRole,
      child: child,
    );
  }

  @override
  Widget buildWide(BuildContext context) {
    return CustomerLayoutWide(
      userRole: userRole,
      child: child,
    );
  }
}