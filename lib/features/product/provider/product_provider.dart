import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/http/api_service.dart';
import '../data/product_api.dart';
import '../data/product_model.dart';
import '../data/product_repository.dart';
import '../data/product_repository_impl.dart';

/// API PROVIDER
final productApiProvider = Provider<ProductApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProductApi(client);
});

/// REPOSITORY PROVIDER
final productRepoProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productApiProvider));
});

/// STATE NOTIFIER PROVIDER
final productNotifierProvider =
StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref.watch(productRepoProvider));
});

/// PRODUCT STATE
class ProductState {
  final List<Product> products;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ProductState({
    required this.products,
    required this.isLoading,
    this.isSaving = false,
    this.error,
  });

  ProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

/// PRODUCT NOTIFIER
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductRepository _repo;

  ProductNotifier(this._repo) : super(
    const ProductState(
      products: [],
      isLoading: false,
    ),
  ) {
    loadProducts();
  }

  /// LOAD PRODUCTS
  Future<void> loadProducts() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final products = await _repo.getProducts();

      if (!mounted) return;

      state = state.copyWith(
        products: products,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// CREATE PRODUCT
  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(
        isSaving: true,
        error: null,
      );

      final product = await _repo.createProduct(data);

      if (!mounted) return false;

      final updatedList = [
        product,
        ...state.products,
      ];

      state = state.copyWith(
        products: updatedList,
        isSaving: false,
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );

      return false;
    }
  }

  /// UPDATE PRODUCT
  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(
        isSaving: true,
        error: null,
      );

      final updatedProduct = await _repo.updateProduct(id, data);

      if (!mounted) return false;

      final updatedList = state.products.map((product) {
        if (product.id == id) {
          return updatedProduct;
        }

        return product;
      }).toList();

      state = state.copyWith(
        products: updatedList,
        isSaving: false,
      );

      return true;
    } catch (e) {
      if (!mounted) return false;

      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );

      return false;
    }
  }

  /// DELETE PRODUCT
  Future<bool> deleteProduct(int id) async {
    try {
      final oldList = state.products;

      /// Optimistic update
      final updatedList = oldList.where((p) {
        return p.id != id;
      }).toList();

      state = state.copyWith(products: updatedList);

      await _repo.deleteProduct(id);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }
}