
import 'package:flutter_riverpod/legacy.dart';

class DashboardFilterState {
  final String selectedStatus;
  final String selectedRegion;
  final String selectedProduct;
  final String searchQuery;
  final bool isListView;

  const DashboardFilterState({
    this.selectedStatus = 'All Status',
    this.selectedRegion = 'All Regions',
    this.selectedProduct = 'All Product',
    this.searchQuery = '',
    this.isListView = true,
  });

  DashboardFilterState copyWith({
    String? selectedStatus,
    String? selectedRegion,
    String? selectedProduct,
    String? searchQuery,
    bool? isListView,
  }) {
    return DashboardFilterState(
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      searchQuery: searchQuery ?? this.searchQuery,
      isListView: isListView ?? this.isListView,
    );
  }
}

class DashboardFilterNotifier extends StateNotifier<DashboardFilterState> {
  DashboardFilterNotifier() : super(const DashboardFilterState());

  void setStatus(String value) =>
      state = state.copyWith(selectedStatus: value);

  void setRegion(String value) =>
      state = state.copyWith(selectedRegion: value);

  void setProduct(String value) =>
      state = state.copyWith(selectedProduct: value);

  void setSearch(String value) =>
      state = state.copyWith(searchQuery: value);

  void setView(bool isListView) =>
      state = state.copyWith(isListView: isListView);

  void clearFilters() {
    state = state.copyWith(
      selectedStatus: 'All Status',
      selectedRegion: 'All Regions',
      selectedProduct: 'All Product',
      searchQuery: '',
    );
  }
}

final dashboardFilterProvider =
StateNotifierProvider<DashboardFilterNotifier, DashboardFilterState>(
      (ref) => DashboardFilterNotifier(),
);