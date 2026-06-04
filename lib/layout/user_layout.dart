import 'package:air_water/layout/view/customer/customer_layout_middle.dart';
import 'package:air_water/layout/view/customer/customer_layout_narrow.dart';
import 'package:air_water/layout/view/customer/customer_layout_wide.dart';
import 'package:air_water/layout/view/others/others_layout_middle.dart';
import 'package:air_water/layout/view/others/others_layout_narrow.dart';
import 'package:air_water/layout/view/others/others_layout_wide.dart';
import 'package:flutter/material.dart';

import '../core/responsive/screen_layout_builder.dart';
import '../core/user_config/user_role.dart';



class CustomerLayout extends ScreenLayoutBuilder {
  const CustomerLayout({super.key, required super.child});

  @override
  Widget buildNarrow(BuildContext context) {
    return CustomerLayoutNarrow(child: child);
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return CustomerLayoutMiddle(child: child);
  }

  @override
  Widget buildWide(BuildContext context) {
    return CustomerLayoutWide(child: child);
  }
}

class OthersLayout extends ScreenLayoutBuilder {
  const OthersLayout({super.key, required super.child, required this.userRole});
  final UserRole userRole;

  @override
  Widget buildNarrow(BuildContext context) {
    return OthersLayoutNarrow(child: child);
  }

  @override
  Widget buildMiddle(BuildContext context) {
    return OthersLayoutMiddle(child: child);
  }

  @override
  Widget buildWide(BuildContext context) {
    return OthersLayoutWide(userRole: userRole, child: child);
  }
}
