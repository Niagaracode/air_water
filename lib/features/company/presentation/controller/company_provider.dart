import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/company_model.dart';
import '../../data/api/company_api.dart';
import '../../domain/repository/company_repository.dart';
import '../../data/repository/company_repository_impl.dart';
import '../../../../core/network/api_client.dart';

final companyApiProvider = Provider(
  (ref) => CompanyApi(ref.read(apiClientProvider)),
);

final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => CompanyRepositoryImpl(ref.read(companyApiProvider)),
);

class CompanyState {
  final List<CompanyGroup> groupedCompanies;
  final Set<String> expandedGroups;
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
    this.expandedGroups = const {},
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
    Set<String>? expandedGroups,
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
      expandedGroups: expandedGroups ?? this.expandedGroups,
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
    Future.microtask(() => loadGroupedCompanies());
    return CompanyState();
  }

  Future<void> loadGroupedCompanies() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    state = state.copyWith(isLoading: true, error: null);

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

      final updatedGroupedCompanies = response.data;
      final expandedGroups = <String>{};

      // Always expand the first group by default
      if (updatedGroupedCompanies.isNotEmpty) {
        expandedGroups.add(updatedGroupedCompanies.first.name);
      }

      state = state.copyWith(
        groupedCompanies: updatedGroupedCompanies,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
        totalEntries: response.pagination.total,
        expandedGroups: expandedGroups,
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
      state = state.copyWith(
        groupedCompanies: [...state.groupedCompanies, ...response.data],
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
    loadGroupedCompanies();
  }

  void setStatus(int? status) {
    if (status == null) {
      state = state.copyWith(clearStatus: true);
    } else {
      state = state.copyWith(selectedStatus: status);
    }
    loadGroupedCompanies();
  }

  void setDate(String? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(selectedDate: date);
    }
    loadGroupedCompanies();
  }

  void toggleGroup(String companyName) {
    final expanded = Set<String>.from(state.expandedGroups);
    if (expanded.contains(companyName)) {
      expanded.clear();
    } else {
      expanded.clear();
      expanded.add(companyName);
    }
    state = state.copyWith(expandedGroups: expanded);
  }

  Future<bool> createCompany(CompanyCreateRequest request) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(companyRepositoryProvider);
      await repository.createCompany(request);
      await loadGroupedCompanies();
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  /// Reload data from API but keep the current expanded groups intact.
  Future<void> _reloadKeepingState() async {
    final currentExpanded = Set<String>.from(state.expandedGroups);

    try {
      final repository = ref.read(companyRepositoryProvider);
      final response = await repository.getGroupedCompanies(
        page: state.page,
        limit: _limit,
        search: state.searchName,
        status: state.selectedStatus,
        date: state.selectedDate,
      );

      // Keep expanded groups that still exist in the new data
      final newNames = response.data.map((g) => g.name).toSet();
      final preserved = currentExpanded.intersection(newNames);
      if (preserved.isEmpty && response.data.isNotEmpty) {
        preserved.add(response.data.first.name);
      }

      state = state.copyWith(
        groupedCompanies: response.data,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
        totalEntries: response.pagination.total,
        expandedGroups: preserved,
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
