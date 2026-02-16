import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/product_provider.dart';
import '../widgets/product_table.dart';


class ProductWide extends ConsumerWidget {
  const ProductWide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);

    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (list) {
        return ProductTable(list);
      },
    );
  }
}