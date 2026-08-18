import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/product/presentation/view/product_edit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/helpers/app_colors_helper.dart';
import '../../../../shared/widgets/view_header.dart';
import '../../data/product_model.dart';
import '../../provider/product_provider.dart';

class ProductNarrow extends ConsumerWidget {
  const ProductNarrow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productNotifierProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () {
          _showProductBottomSheet(
            context,
            product: const Product(
              id: 0,
              name: '',
              productCode: '',
              description: '',
              scmM3: 0,
              specificGravity: 0,
            ),
            isEditing: false,
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add product', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: state.isLoading && state.products.isEmpty
                ? const Center(
              child: CircularProgressIndicator(),
            ) : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = state.products[index];

                return ListTile(
                  onTap: () {
                    _showProductBottomSheet(
                      context,
                      product: product,
                      isEditing: true,
                    );
                  },
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColorsHelper.getGasTypeColor(product.name),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(product.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Specific gravity',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              product.specificGravity.toStringAsFixed(3),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SCM / m³',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text(
                              product.scmM3.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'PRODUCT MANAGEMENT',
      subtitle:
      'Manage fluid products, their descriptions, and specific properties like SCM/M3 and gravity.',
      buttonText: null,
      onPressed: () {
        //_showAddProductSideSheet(context);
      },
    );
  }

  void _showProductBottomSheet(BuildContext context, {required Product product, required bool isEditing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: 420,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              // Header with title and close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Product' : 'Add Product',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Form content
              Expanded(
                child: ProductEditView(
                  product: product, isNarrow: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}