import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme/app_theme.dart';
import '../../provider/product_provider.dart';
import '../../data/product_model.dart';
import '../view/product_edit_view.dart';
import '../../../../shared/widgets/app_table.dart';

class ProductWide extends ConsumerStatefulWidget {
  const ProductWide({super.key});

  @override
  ConsumerState<ProductWide> createState() => _ProductWideState();
}

class _ProductWideState extends ConsumerState<ProductWide> {


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productNotifierProvider);

    return Scaffold(
      backgroundColor: primary.withValues(alpha: 0.04),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: _buildHeader(context),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: _buildDataTable(context, state.products),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 32),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRODUCT MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage fluid products, their descriptions, and specific properties like SCM/M3 and gravity.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddProductSideSheet(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  'Add Product',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, List<Product> list) {
    return DataTable2(
      dataRowColor: WidgetStateProperty.all(Colors.white),
      border: TableBorder(
        bottom: BorderSide(color: Colors.black12, width: 0.6),
        left: BorderSide(color: Colors.black12, width: 0.6),
        right: BorderSide(color: Colors.black12, width: 0.6),
      ),
      columnSpacing: 12,
      horizontalMargin: 12,
      minWidth: 800,
      headingRowHeight: 45,
      dataRowHeight: 50,
      dividerThickness: 0.4,
      headingRowColor: WidgetStateProperty.all(const Color(0xFF141E7A)),
      headingTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),

      columns: [
        DataColumn2(
          label: AppTableHeaderCell('SI.NO'),
          size: ColumnSize.S,
        ),
        const DataColumn2(
          label: AppTableHeaderCell('Product Name'),
          size: ColumnSize.L,
        ),
        const DataColumn2(
          label: AppTableHeaderCell('Description'),
          size: ColumnSize.L,
        ),
        const DataColumn2(
          label: AppTableHeaderCell('Scm / m3'),
          fixedWidth: 150.0,
        ),
        const DataColumn2(
          label: AppTableHeaderCell('Specific gravity'),
          fixedWidth: 150.0,
        ),
        const DataColumn2(
          label: AppTableHeaderCell('Action'),
          fixedWidth: 100.0,
        ),
      ],

      rows: List.generate(list.length, (index) {
        final p = list[index];
        return DataRow(
          cells: [
            DataCell(AppTableCell((index + 1).toString().padLeft(2, '0'), textAlign: TextAlign.center)),
            DataCell(AppTableCell(p.name, bold: true)),
            DataCell(AppTableCell(p.description, textAlign: TextAlign.left)),
            DataCell(AppTableCell(p.scmM3.toStringAsFixed(2), textAlign: TextAlign.center)),
            DataCell(AppTableCell(p.specificGravity.toStringAsFixed(3))),
            DataCell(
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
                    onPressed: () => _showProductSideSheet(context, p),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteProduct(context, ref, p),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showAddProductSideSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Add Product",
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
              child: ProductEditView(
                product: Product(
                  id: 0,
                  name: '',
                  productCode: '',
                  description: '',
                  scmM3: 0.0,
                  specificGravity: 0.0,
                ),
              ),
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

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Product'),
            content: const Text(
                'Are you sure you want to delete this product? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final success = await ref
        .read(productNotifierProvider.notifier)
        .deleteProduct(product.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Product deleted successfully"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Failed to delete product: ${ref
              .read(productNotifierProvider)
              .error}"),
        ),
      );
    }
  }
}
