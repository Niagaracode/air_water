import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/product_api.dart';
import '../data/product_model.dart';
import '../data/product_repository.dart';
import '../data/product_repository_impl.dart';

final productApiProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return ProductApi(client);
});

final productRepoProvider = Provider<ProductRepository>((ref) {
  final api = ref.watch(productApiProvider);
  return ProductRepositoryImpl(api);
});

final productListProvider =
FutureProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepoProvider);
  return repo.getProducts();
});