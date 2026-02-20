import 'package:air_water/features/group/presentation/view/group_middle.dart';
import 'package:air_water/features/group/presentation/view/group_narrow.dart';
import 'package:air_water/features/group/presentation/view/group_wide.dart';

import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class UserGroupLayout extends PageLayoutBuilder {
  const UserGroupLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const GroupNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const GroupMiddle();

  @override
  Widget buildWide(BuildContext context) => const GroupWide();
}
