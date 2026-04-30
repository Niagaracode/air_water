import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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

class ProductState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  ProductState({required this.products, required this.isLoading, this.error});

  ProductState copyWith({List<Product>? products, bool? isLoading, String? error}) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repo;

  ProductNotifier(this._repo) : super(ProductState(products: [], isLoading: false)) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repo.getProducts();
      state = state.copyWith(products: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      await _repo.createProduct(data);
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      await _repo.updateProduct(id, data);
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final productNotifierProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final repo = ref.watch(productRepoProvider);
  return ProductNotifier(repo);
});

// Legacy support if needed, but better to use productNotifierProvider
final productListProvider = FutureProvider<List<Product>>((ref) {
  final state = ref.watch(productNotifierProvider);
  return state.products;
});
