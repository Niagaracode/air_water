import 'package:flutter/material.dart';

import '../../data/product_model.dart';
import '../../../../shared/widgets/app_table.dart';
import '../view/product_edit_view.dart';

class ProductTable extends StatelessWidget {
  final List<Product> list;
  final bool showHeader;
  const ProductTable(this.list, {super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header — navy
        if (showHeader)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A),
              border: Border(
                top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                const AppTableHeaderCell('SI.NO', width: 60),
                const AppTableHeaderCell('Product Name', flex: 2),
                const AppTableHeaderCell('Description', flex: 3),
                const AppTableHeaderCell('SCM / M3', flex: 1),
                const AppTableHeaderCell('Specific Gravity', flex: 1),
                const AppTableHeaderCell('Action', width: 80),
              ],
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final p = list[index];
            return _buildProductRow(context, p, index);
          },
        ),
        const AppTableBottomCap(),
      ],
    );
  }

  Widget _buildProductRow(BuildContext context, Product p, int index) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppTableCell((index + 1).toString().padLeft(2, '0'), width: 60),
          AppTableCell(p.name, flex: 2, bold: true),
          AppTableCell(p.description, flex: 3),
          AppTableCell(p.scmM3.toStringAsFixed(2), flex: 1),
          AppTableCell(p.specificGravity.toStringAsFixed(3), flex: 1),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppTableActionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                  onTap: () => _showProductSideSheet(context, p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSideSheet(BuildContext context, Product product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Edit Product",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: SizedBox(
              width: 600,
              height: double.infinity,
              child: ProductEditView(product: product),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero);

        return SlideTransition(
          position: tween.animate(animation),
          child: child,
        );
      },
    );
  }
}