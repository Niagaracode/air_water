import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/http/api_service.dart';
import '../../data/model/tank_model.dart';
import '../../data/tank_api.dart';
import '../../data/tank_repository.dart';
import '../../data/tank_repository_impl.dart';
import '../../../site/presentation/model/site_model.dart';
import '../../../user/presentation/controller/user_provider.dart';


final allTanksProvider = FutureProvider<List<Tank>>((ref) {
  final repo = ref.watch(tankRepositoryProvider);
  return repo.getTanks();
});

class TankState {
  final List<TankGroup> groupedTanks;
  final List<AssetGroupData> assetGroups;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final int totalEntries;
  final bool hasMore;
  final Set<String> expandedGroups;
  final List<TankProduct> products;
  final String searchSite;
  final String searchTank;
  final int? selectedStatus;

  TankState({
    required this.groupedTanks,
    this.assetGroups = const [],
    required this.isLoading,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.totalEntries = 0,
    this.hasMore = false,
    required this.expandedGroups,
    this.products = const [],
    this.searchSite = '',
    this.searchTank = '',
    this.selectedStatus,
  });

  TankState copyWith({
    List<TankGroup>? groupedTanks,
    List<AssetGroupData>? assetGroups,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    int? totalEntries,
    bool? hasMore,
    Set<String>? expandedGroups,
    List<TankProduct>? products,
    String? searchSite,
    String? searchTank,
    int? selectedStatus,
    bool clearError = false,
  }) {
    return TankState(
      groupedTanks: groupedTanks ?? this.groupedTanks,
      assetGroups: assetGroups ?? this.assetGroups,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalEntries: totalEntries ?? this.totalEntries,
      hasMore: hasMore ?? this.hasMore,
      expandedGroups: expandedGroups ?? this.expandedGroups,
      products: products ?? this.products,
      searchSite: searchSite ?? this.searchSite,
      searchTank: searchTank ?? this.searchTank,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class TankNotifier extends Notifier<TankState> {

  @override
  TankState build() {
    ref.keepAlive();
    
    ref.listen(userProvider, (previous, next) {
      if (previous?.currentUser == null && next.currentUser != null) {
        loadGroupedTanks();
      }
    });

    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser != null) {
      Future.microtask(() => loadGroupedTanks());
    }

    return TankState(groupedTanks: [], isLoading: false, expandedGroups: {});
  }

  void setSearchSite(String value) {
    state = state.copyWith(searchSite: value);
  }

  void setSearchTank(String value) {
    state = state.copyWith(searchTank: value);
  }

  void setStatus(int? value) {
    state = state.copyWith(selectedStatus: value);
    loadGroupedTanks();
  }

  void clearFilters() {
    state = state.copyWith(
      searchSite: '',
      searchTank: '',
      selectedStatus: null,
    );
    loadGroupedTanks();
  }

  Future<void> loadGroupedTanks() async {
    if (ref.read(userProvider).currentUser == null) return;

    state = state.copyWith(isLoading: true, page: 1, groupedTanks: []);
    try {
      final repository = ref.read(tankRepositoryProvider);
      final response = await repository.getTanksGrouped(
        page: 1,
        siteName: state.searchSite.isEmpty ? null : state.searchSite,
        tankName: state.searchTank.isEmpty ? null : state.searchTank,
        status: state.selectedStatus,
      );

      final expandedGroups = <String>{};
      for (var group in response.data) {
        expandedGroups.add(group.siteName);
      }

      state = state.copyWith(
        groupedTanks: response.data,
        assetGroups: response.assetGroups,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        expandedGroups: expandedGroups,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTank(TankCreateRequest request) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.createTank(request);
      state = state.copyWith(isProcessing: false);
      await loadGroupedTanks();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateTank(int id, TankCreateRequest request) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.updateTank(id, request);
      state = state.copyWith(isProcessing: false);
      await loadGroupedTanks();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTank(int id) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.deleteTank(id);
      state = state.copyWith(isProcessing: false);
      await loadGroupedTanks();
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<SiteAutocompleteInfo>> searchSites(String query, {int? companyId}) async {
    try {
      final repository = ref.read(tankRepositoryProvider);
      return await repository.getSitesForTankAutocomplete(q: query, companyId: companyId);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDropdowns() async {
    final repository = ref.read(tankRepositoryProvider);
    return await repository.getTankDropdowns();
  }

  Future<List<String>> getTankNameSuggestions(String query) async {
    try {
      final repository = ref.read(tankRepositoryProvider);
      return await repository.getTankNameSuggestions(q: query);
    } catch (e) {
      return [];
    }
  }

  Future<List<TankProduct>> getProducts() async {
    try {
      final repository = ref.read(tankRepositoryProvider);
      final products = await repository.getProducts();
      state = state.copyWith(products: products);
      return products;
    } catch (e) {
      return [];
    }
  }
}

final tankApiProvider = Provider<TankApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return TankApi(client);
});

final tankRepositoryProvider = Provider<TankRepository>((ref) {
  final api = ref.watch(tankApiProvider);
  return TankRepositoryImpl(api);
});

final tankNotifierProvider = NotifierProvider<TankNotifier, TankState>(
  TankNotifier.new,
);