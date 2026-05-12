import 'package:air_water/features/product/provider/product_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/product_repository.dart';

final productNotifierProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final repo = ref.watch(productRepoProvider);
  return ProductNotifier(repo);
});
class ProductNotifier extends StateNotifier<ProductState> {

  final ProductRepository _repo;

  ProductNotifier(this._repo) : super(
    ProductState(
      products: [],
      isLoading: false,
    ),
  ) {
    loadProducts();
  }

  Future<void> loadProducts() async {

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {

      final list = await _repo.getProducts();

      if (!mounted) return;

      state = state.copyWith(
        products: list,
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

  /// CREATE
  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      final createdProduct = await _repo.createProduct(data);
      final updatedList = [
        createdProduct, ...state.products,
      ];
      state = state.copyWith(products: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// UPDATE
  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final updatedProduct = await _repo.updateProduct(id, data);
      final updatedList = state.products.map((p) {
        if (p.id == id) {
          return updatedProduct;
        }
        return p;
      }).toList();
      state = state.copyWith(products: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// DELETE
  Future<bool> deleteProduct(int id) async {
    try {
      await _repo.deleteProduct(id);
      final updatedList = state.products.where((p) {
        return p.id != id;
      }).toList();
      state = state.copyWith(products: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}