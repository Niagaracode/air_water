import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../data/product_model.dart';

class ProductEditView extends StatelessWidget {
  final Product product;

  const ProductEditView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController(text: product.name);
    final descCtrl = TextEditingController(text: product.description);
    final gravityCtrl =
    TextEditingController(text: product.specificGravity.toString());
    final scmCtrl =
    TextEditingController(text: product.scmM3.toString());

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
                  onPressed: () => Navigator.pop(context),
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

                      /// ROW 1
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

                      /// ROW 2
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
                              label: "SCM/M3",
                              child: AppTextField(
                                controller: scmCtrl,
                                hint: "SCM/M3",
                                keyboardType: TextInputType.number,
                              )
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      /// ROW 3
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: "Product Group",
                              child: _dropdown(["Gas", "Liquid", "Other"]),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _field(
                              label: "Display Units",
                              child: _dropdown(["kg", "litre", "m3"]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      /// SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Save Changes"),
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

  /// ---------- UI HELPERS ----------

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


  Widget _dropdown(List<String> items) {
    return DropdownButtonFormField<String>(
      value: items.first,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {},
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}