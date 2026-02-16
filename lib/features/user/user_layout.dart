import 'package:air_water/features/user/presentation/view/user_middle.dart';
import 'package:air_water/features/user/presentation/view/user_narrow.dart';
import 'package:air_water/features/user/presentation/view/user_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class UserLayout extends PageLayoutBuilder {
  const UserLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const UserNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const UserMiddle();

  @override
  Widget buildWide(BuildContext context) => const UserWide();
}
