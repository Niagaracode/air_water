import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/company_model.dart';
import '../../data/api/company_api.dart';
import '../../domain/repository/company_repository.dart';
import '../../data/repository/company_repository_impl.dart';
import '../../../../core/network/http/api_service.dart';
import '../../../user/presentation/controller/user_provider.dart';

final companyApiProvider = Provider(
  (ref) => CompanyApi(ref.read(apiClientProvider)),
);

final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => CompanyRepositoryImpl(ref.read(companyApiProvider)),
);

class CompanyState {
  final List<CompanyGroup> groupedCompanies;
  final bool isLoading;

  final bool hasMore;
  final int page;
  final int totalEntries;
  final String? selectedDate;
  final bool isProcessing;
  final String? error;
  final String searchName;
  final int? selectedStatus;

  CompanyState({
    this.groupedCompanies = const [],
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

  CompanyState copyWith({
    List<CompanyGroup>? groupedCompanies,
    bool? isLoading,

    bool? hasMore,
    int? page,
    int? totalEntries,
    String? error,
    String? searchName,
    int? selectedStatus,
    String? selectedDate,
    bool? isProcessing,
    bool clearStatus = false,
    bool clearDate = false,
  }) {
    return CompanyState(
      groupedCompanies: groupedCompanies ?? this.groupedCompanies,
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

class CompanyNotifier extends Notifier<CompanyState> {
  static const int _limit = 50;
  int _lastRequestTimestamp = 0;

  @override
  CompanyState build() {
    ref.keepAlive();
    
    // Listen to user changes to trigger reload when current user data (and companyId) becomes available
    ref.listen(userProvider, (previous, next) {
      if (previous?.currentUser == null && next.currentUser != null) {
        loadGroupedCompanies(isReload: true);
      }
    });

    // Initial load
    Future.microtask(() => loadGroupedCompanies());
    return CompanyState();
  }

  List<CompanyGroup> _filterCompanies(List<CompanyGroup> companies) {
    return companies;
  }

  Future<void> loadGroupedCompanies({bool isReload = false}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    if (state.groupedCompanies.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repository = ref.read(companyRepositoryProvider);
      final response = await repository.getGroupedCompanies(
        page: 1,
        limit: _limit,
        search: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
      );

      // Verify that this is still the latest request
      if (timestamp != _lastRequestTimestamp) return;

      final updatedGroupedCompanies = _filterCompanies(response.data);
      
      // Calculate how many were filtered to adjust total count if needed

      final filteredOutCount = response.data.length - updatedGroupedCompanies.length;

      state = state.copyWith(
        groupedCompanies: updatedGroupedCompanies,
        isLoading: false,
        page: 1,
        totalEntries: response.pagination.total - filteredOutCount,
      );

    } catch (e) {
      if (timestamp != _lastRequestTimestamp) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(companyRepositoryProvider);
      final response = await repository.getGroupedCompanies(
        page: nextPage,
        limit: _limit,
        search: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
      );
      
      final filteredNew = _filterCompanies(response.data);


      state = state.copyWith(
        groupedCompanies: [...state.groupedCompanies, ...filteredNew],
        isLoading: false,
        page: nextPage,
        totalEntries: state.totalEntries + filteredNew.length,
      );

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchName(String name) {
    state = state.copyWith(searchName: name);
    // Explicit trigger required from UI
  }

  void clearFilters() {
    state = state.copyWith(searchName: '', clearStatus: true, clearDate: true);
    loadGroupedCompanies(isReload: true);
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
    loadGroupedCompanies(isReload: true);
  }

  void setDate(String? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(selectedDate: date);
    }
    loadGroupedCompanies(isReload: true);
  }

  Future<bool> createCompany(CompanyCreateRequest request) async {

    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(companyRepositoryProvider);
      await repository.createCompany(request);
      await loadGroupedCompanies(isReload: true);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  /// Reload data from API
  Future<void> _reloadKeepingState() async {
    try {

      final repository = ref.read(companyRepositoryProvider);
      final response = await repository.getGroupedCompanies(
        page: state.page,
        limit: _limit,
        search: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
      );

      final filtered = _filterCompanies(response.data);
      final filteredOutCount = response.data.length - filtered.length;
      state = state.copyWith(
        groupedCompanies: filtered,
        isLoading: false,
        page: 1,
        totalEntries: response.pagination.total - filteredOutCount,
      );



    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateCompany(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(companyRepositoryProvider);
      await repository.updateCompany(id, data);
      await _reloadKeepingState();
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCompany(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(companyRepositoryProvider);
      await repository.deleteCompany(id);
      await _reloadKeepingState();
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final companyNotifierProvider = NotifierProvider<CompanyNotifier, CompanyState>(
  CompanyNotifier.new,
);
