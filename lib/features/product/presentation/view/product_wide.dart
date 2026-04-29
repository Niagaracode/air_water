import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../provider/product_provider.dart';
import '../../data/product_model.dart';
import '../widgets/product_table.dart';
import '../view/product_edit_view.dart';
import '../../../../shared/widgets/app_table.dart';

class ProductWide extends ConsumerStatefulWidget {
  const ProductWide({super.key});

  @override
  ConsumerState<ProductWide> createState() => _ProductWideState();
}

class _ProductWideState extends ConsumerState<ProductWide> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productNotifierProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildHeader(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildFixedTableHeader(),
          ),
          Expanded(
            child: Builder(builder: (context) {
              if (state.isLoading && state.products.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(color: Color(0xFF141E7A)),
                  ),
                );
              }
              if (state.error != null && state.products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ProductTable(state.products, showHeader: false),
              );
            }),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFixedTableHeader() {
    return Container(
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                onPressed: () => _showProductSideSheet(context),
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

  void _showProductSideSheet(BuildContext context) {
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
}
