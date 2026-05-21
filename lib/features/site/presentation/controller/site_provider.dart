import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/site_model.dart';
import '../../data/api/site_api.dart';
import '../../data/repository/site_repository.dart';
import '../../data/repository/site_repository_impl.dart';
import '../../../../core/network/http/api_service.dart';
import '../../../../features/company/presentation/controller/company_provider.dart';
import '../../../../features/company/presentation/model/company_model.dart';
import '../../../../features/user/presentation/controller/user_provider.dart';

final siteApiProvider = Provider(
  (ref) => SiteApi(ref.read(apiClientProvider)),
);

final siteRepositoryProvider = Provider<SiteRepository>(
  (ref) => SiteRepositoryImpl(ref.read(siteApiProvider)),
);

class SiteState {
  final List<Site> sites;
  final List<SiteGroup> groupedSites;
  final bool isLoading;
  final bool isProcessing;
  final bool hasMore;
  final int page;
  final int totalEntries;
  final String? error;
  final String searchName;
  final int? selectedStatus;
  final String? selectedDate;

  SiteState({
    this.sites = const [],
    this.groupedSites = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.hasMore = true,
    this.page = 1,
    this.totalEntries = 0,
    this.error,
    this.searchName = '',
    this.selectedStatus,
    this.selectedDate,
  });

  SiteState copyWith({
    List<Site>? sites,
    List<SiteGroup>? groupedSites,
    bool? isLoading,
    bool? isProcessing,
    bool? hasMore,
    int? page,
    int? totalEntries,
    String? error,
    String? searchName,
    int? selectedStatus,
    String? selectedDate,
    bool clearStatus = false,
    bool clearDate = false,
  }) {
    return SiteState(
      sites: sites ?? this.sites,
      groupedSites: groupedSites ?? this.groupedSites,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalEntries: totalEntries ?? this.totalEntries,
      error: error ?? this.error,
      searchName: searchName ?? this.searchName,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
    );
  }
}

class SiteNotifier extends Notifier<SiteState> {
  static const int _limit = 50;

  @override
  SiteState build() {
    ref.keepAlive();
    
    ref.listen(userProvider, (previous, next) {
      if (previous?.currentUser == null && next.currentUser != null) {
        loadGroupedSites(isReload: true);
      }
    });

    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser != null) {
      Future.microtask(() => loadGroupedSites());
    }
    
    return SiteState();
  }

  Future<void> loadGroupedSites({bool isReload = false}) async {
    if (ref.read(userProvider).currentUser == null) return;

    if (state.isLoading) return;

    if (state.groupedSites.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repository = ref.read(siteRepositoryProvider);
      final response = await repository.getSitesGrouped(
        page: 1,
        limit: _limit,
        name: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
      );

      state = state.copyWith(
        groupedSites: response.data,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
        totalEntries: response.pagination.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(siteRepositoryProvider);
      final response = await repository.getSitesGrouped(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
      );

      state = state.copyWith(
        groupedSites: [...state.groupedSites, ...response.data],
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchName(String name) {
    state = state.copyWith(searchName: name);
  }

  void clearFilters() {
    state = state.copyWith(searchName: '', clearStatus: true, clearDate: true);
    loadGroupedSites(isReload: true);
  }

  Future<List<SiteAutocompleteInfo>> searchSites(String query) async {
    try {
      final repository = ref.read(siteRepositoryProvider);
      return await repository.getSiteAutocomplete(q: query);
    } catch (e) {
      return [];
    }
  }

  Future<List<CompanyAutocompleteInfo>> searchCompanies(String query) async {
    try {
      final repository = ref.read(companyRepositoryProvider);
      final results = await repository.getCompanyAutocomplete(q: query);
      // Filter out Super Admin company (ID 1)
      return results.where((c) => c.companyId != 1).toList();
    } catch (e) {
      return [];
    }
  }

  void setStatus(int? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
    loadGroupedSites(isReload: true);
  }

  void setDate(String? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(selectedDate: date);
    }
    loadGroupedSites(isReload: true);
  }

  Future<bool> createSite(SiteCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(siteRepositoryProvider);
      await repository.createSite(request);
      await loadGroupedSites(isReload: true);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateSite(int id, SiteCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(siteRepositoryProvider);
      await repository.updateSite(id, request);
      await loadGroupedSites(isReload: true);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSite(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(siteRepositoryProvider);
      await repository.deleteSite(id);
      await loadGroupedSites(isReload: true);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final siteNotifierProvider = NotifierProvider<SiteNotifier, SiteState>(
  SiteNotifier.new,
);
