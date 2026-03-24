import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';
import 'presentation/view/profile_narrow.dart';
import 'presentation/view/profile_middle.dart';
import 'presentation/view/profile_wide.dart';

class ProfileLayout extends PageLayoutBuilder {
  const ProfileLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const ProfileNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const ProfileMiddle();

  @override
  Widget buildWide(BuildContext context) => const ProfileWide();
}
