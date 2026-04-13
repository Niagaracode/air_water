import 'package:air_water/features/site/presentation/view/site_middle.dart';
import 'package:air_water/features/site/presentation/view/site_narrow.dart';
import 'package:air_water/features/site/presentation/view/site_wide.dart';
import 'package:flutter/cupertino.dart';

import '../../core/responsive/page_layout_builder.dart';

class SiteLayout extends PageLayoutBuilder {
  const SiteLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) => const SiteNarrow();

  @override
  Widget buildMiddle(BuildContext context) => const SiteMiddle();

  @override
  Widget buildWide(BuildContext context) => const SiteWide();
}
