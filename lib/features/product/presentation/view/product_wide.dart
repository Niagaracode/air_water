import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/table_data_cell.dart';
import '../../../../shared/widgets/table_header_cell.dart';
import '../../../../shared/widgets/view_header.dart';
import '../../data/product_model.dart';
import '../../provider/product_provider.dart';
import '../view/product_edit_view.dart';

class ProductWide extends ConsumerWidget {

  const ProductWide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final state = ref.watch(productNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: Column(
        children: [
          _buildHeader(context),
          SizedBox(child: state.isLoading && state.products.isEmpty ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildLoadingView(),
          )
              : Padding(padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: _buildDataTable(context, ref, state.products),
            ),
          ),
        ],
      ),
    );
  }

  /// HEADER
  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'PRODUCT MANAGEMENT',
      subtitle:
      'Manage fluid products, their descriptions, and specific properties like SCM/M3 and gravity.',
      buttonText: 'Add Product',
      onPressed: () {
        _showAddProductSideSheet(context);
      },
    );
  }

  Widget _buildLoadingView() {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(6, (index) => Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.all(5),
              child: Expanded(child: _skeletonBox(height: 40)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({double? width, double height = 16, double radius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// TABLE
  Widget _buildDataTable(BuildContext context, WidgetRef ref, List<Product> list) {

    double screenHeight = MediaQuery.sizeOf(context).height;
    double stateHeight = (list.length * 45) + 50;

    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: stateHeight > (screenHeight-200) ? (screenHeight-205) : stateHeight,
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
            fixedWidth: 60,
            label: Center(child: TableHeaderCell(label: 'SI.NO')),
          ),
          const DataColumn2(
            size: ColumnSize.M,
            label: Center(child: TableHeaderCell(label: 'PRODUCT NAME')),
          ),
          const DataColumn2(
            size: ColumnSize.L,
            label: TableHeaderCell(label: 'DESCRIPTION')
          ),
          const DataColumn2(
            size: ColumnSize.S,
            label: Center(child: TableHeaderCell(label: 'SPECIFIC GRAVITY')),
          ),
          const DataColumn2(
            size: ColumnSize.M,
            label: Center(child: TableHeaderCell(label: 'STANDARD VOLUME / M3')),
          ),
          const DataColumn2(
            fixedWidth: 120,
            label: Center(child: TableHeaderCell(label: 'ACTIONS')),
          ),
        ],

        rows: List.generate(
          list.length, (index) {
            final p = list[index];
            return DataRow(
              cells: [
                DataCell(Center(child: TableDataCell(label: '${index + 1}'))),
                DataCell(Center(child: TableDataCell(label: p.name, bold: true))),
                DataCell(TableDataCell(label: p.description)),
                DataCell(Center(child: TableDataCell(label: (p.specificGravity).toStringAsFixed(3)))),
                DataCell(Center(child: TableDataCell(label: p.scmM3.toStringAsFixed(2)))),
                DataCell(Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      AppTableActionButton(
                        icon:
                        Icons.edit_outlined,
                        color: primary,
                        bg: primary.withValues(alpha: 0.1),
                        onTap: () {
                          _showProductSideSheet(context, p);
                        },
                      ),
                      const SizedBox(width: 8),
                      AppTableActionButton(icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFDC2626),
                        bg: const Color(0xFFFEF2F2),
                        onTap: () {
                          _deleteProduct(context, ref, p);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ADD PRODUCT
  void _showAddProductSideSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Product',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: SizedBox(
              width: 600,
              height: double.infinity,
              child: ProductEditView(
                product: const Product(
                  id: 0,
                  name: '',
                  productCode: '',
                  description: '',
                  scmM3: 0,
                  specificGravity: 0,
                ),
              ),
            ),
          ),
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  /// EDIT PRODUCT
  void _showProductSideSheet(BuildContext context, Product product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Product',
      barrierColor: Colors.black54,
      transitionDuration:
      const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 8,
            child: SizedBox(
              width: 600,
              height: double.infinity,
              child: ProductEditView(
                product: product,
              ),
            ),
          ),
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  /// DELETE

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text(
            'Are you sure you want to delete this product?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.of(dialogContext).pop(false);
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await ref
        .read(productNotifierProvider.notifier)
        .deleteProduct(product.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        success ? Colors.green : Colors.red,
        content: Text(
          success
              ? 'Product deleted successfully'
              : ref.read(productNotifierProvider).error ??
              'Delete failed',
        ),
      ),
    );
  }
}