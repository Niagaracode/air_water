import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/product_model.dart';
import '../../provider/product_provider.dart';


class ProductEditView extends ConsumerStatefulWidget {
  final Product product;

  const ProductEditView({super.key, required this.product});

  @override
  ConsumerState<ProductEditView> createState() => _ProductEditViewState();
}

class _ProductEditViewState extends ConsumerState<ProductEditView> {
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController gravityCtrl;
  late TextEditingController scmCtrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.product.name);
    descCtrl = TextEditingController(text: widget.product.description);
    gravityCtrl = TextEditingController(text: widget.product.specificGravity.toString());
    scmCtrl = TextEditingController(text: widget.product.scmM3.toString());
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    gravityCtrl.dispose();
    scmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product name is required"),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final data = {
        'product_name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'specificgravity': double.tryParse(gravityCtrl.text.trim()) ?? 0.0,
        'scm_m3': double.tryParse(scmCtrl.text.trim()) ?? 0.0,
      };

      final notifier = ref.read(productNotifierProvider.notifier);

      final success = widget.product.id == 0
          ? await notifier.createProduct(data)
          : await notifier.updateProduct(widget.product.id, data);

      if (!mounted) return;

      setState(() => isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              widget.product.id == 0
                  ? "Product created successfully"
                  : "Product updated successfully",
            ),
          ),
        );
        Navigator.of(context, rootNavigator: true).pop();
      } else {
        final error = ref.read(productNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              error ?? "Failed to save product",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Product Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                )
              ],
            ),
            const SizedBox(height: 16),

            /// CARD FORM
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: "Product Name *",
                              child: AppTextField(
                                controller: nameCtrl,
                                hint: "Enter product name",
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _field(
                              label: "Specific Gravity",
                              child: AppTextField(
                                controller: gravityCtrl,
                                hint: "Enter specific gravity",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: "Description",
                              child: AppTextField(
                                controller: descCtrl,
                                hint: "Enter description",
                                maxLines: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _field(
                              label: "Standard volume/ cubic meter",
                              child: AppTextField(
                                controller: scmCtrl,
                                hint: "Standard volume/ cubic meter",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Save Changes"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}