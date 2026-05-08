import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/table_data_cell.dart';
import '../../../../shared/widgets/table_header_cell.dart';
import '../../provider/product_provider.dart';
import '../../data/product_model.dart';
import '../view/product_edit_view.dart';

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
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: Column(
        children: [
          _buildHeader(context),
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildDataTable(context, state.products),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      margin: const EdgeInsets.only(left: 26, right: 26, top: 26, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  color: Colors.black38,
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
    );
  }

  Widget _buildDataTable(BuildContext context, List<Product> list) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: (list.length * 45) + 50,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: DataTable2(
        dataRowColor: WidgetStateProperty.all(Colors.white),
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        headingRowHeight: 45,
        dataRowHeight: 45,
        dividerThickness: 0.4,
        headingRowColor: WidgetStateProperty.all(primary.withValues(alpha: 0.1)),
        columns: [
          DataColumn2(
            label: TableHeaderCell(label: 'SI.NO',),
            size: ColumnSize.S,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Product Name'),
            size: ColumnSize.L,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Description'),
            size: ColumnSize.L,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Scm / m3'),
            fixedWidth: 150.0,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Specific gravity'),
            fixedWidth: 150.0,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Action'),
            fixedWidth: 100.0,
          ),
        ],

        rows: List.generate(list.length, (index) {
          final p = list[index];
          return DataRow(
            cells: [
              DataCell(TableDataCell(label: '${index + 1}')),
              DataCell(TableDataCell(label: p.name, bold: true,)),
              DataCell(TableDataCell(label: p.description)),
              DataCell(TableDataCell(label: p.scmM3.toStringAsFixed(2))),
              DataCell(TableDataCell(label: p.specificGravity.toStringAsFixed(3))),
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
      ),
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