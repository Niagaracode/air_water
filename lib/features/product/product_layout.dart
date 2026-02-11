import 'package:air_water/features/product/view/product_wide.dart';
import 'package:air_water/features/product/view/product_narrow.dart';
import 'package:air_water/features/product/view/product_middle.dart';
import 'package:flutter/cupertino.dart';
import '../../core/responsive/page_layout_builder.dart';


class ProductLayout extends PageLayoutBuilder {
  const ProductLayout({super.key});

  @override
  Widget buildNarrow(BuildContext context) =>
      const ProductNarrow();

  @override
  Widget buildMiddle(BuildContext context) =>
      const ProductMiddle();

  @override
  Widget buildWide(BuildContext context) =>
      const ProductWide();
}