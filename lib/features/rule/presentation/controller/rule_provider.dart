import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/rule_model.dart';
import '../../data/api/rule_api.dart';
import '../../domain/repository/rule_repository.dart';
import '../../data/repository/rule_repository_impl.dart';
import '../../../../core/network/api_client.dart';

class RuleState {
  final List<RuleGroup> groupedRules;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final int totalEntries;
  final String searchName;
  final String? parameterType;
  final int? selectedPlantId;
  final int? selectedStatus;

  RuleState({
    this.groupedRules = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.totalEntries = 0,
    this.searchName = '',
    this.parameterType,
    this.selectedPlantId,
    this.selectedStatus,
  });

  RuleState copyWith({
    List<RuleGroup>? groupedRules,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    int? totalEntries,
    String? searchName,
    String? parameterType,
    int? selectedPlantId,
    int? selectedStatus,
    bool clearParameterType = false,
    bool clearPlantId = false,
    bool clearStatus = false,
  }) {
    return RuleState(
      groupedRules: groupedRules ?? this.groupedRules,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
      searchName: searchName ?? this.searchName,
      parameterType: clearParameterType ? null : (parameterType ?? this.parameterType),
      selectedPlantId: clearPlantId ? null : (selectedPlantId ?? this.selectedPlantId),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
  }
}

class RuleNotifier extends Notifier<RuleState> {
  static const int _limit = 50;
  int _lastRequestTimestamp = 0;

  @override
  RuleState build() {
    ref.keepAlive();
    Future.microtask(() => loadRules());
    return RuleState();
  }

  Future<void> loadRules({bool isReload = false}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    if (state.groupedRules.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, page: 1, groupedRules: []);
    }

    try {
      final repository = ref.read(ruleRepositoryProvider);
      final response = await repository.getRulesGrouped(
        page: 1,
        limit: _limit,
        name: state.searchName,
        parameterType: state.parameterType,
        plantId: state.selectedPlantId,
        isActive: state.selectedStatus,
      );

      if (timestamp != _lastRequestTimestamp) return;

      state = state.copyWith(
        groupedRules: response.data,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
      );
    } catch (e) {
      if (timestamp != _lastRequestTimestamp) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(ruleRepositoryProvider);
      final response = await repository.getRulesGrouped(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
        parameterType: state.parameterType,
        plantId: state.selectedPlantId,
        isActive: state.selectedStatus,
      );

      if (timestamp != _lastRequestTimestamp) return;

      final updatedGroups = [...state.groupedRules, ...response.data];

      state = state.copyWith(
        groupedRules: updatedGroups,
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      if (timestamp != _lastRequestTimestamp) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchName(String name) {
    state = state.copyWith(searchName: name);
  }

  void setParameterType(String? type) {
    state = state.copyWith(parameterType: type);
    loadRules(isReload: true);
  }

  void setPlantId(int? plantId) {
    state = state.copyWith(selectedPlantId: plantId);
    loadRules(isReload: true);
  }

  void setSelectedStatus(int? status) {
    state = state.copyWith(selectedStatus: status);
    loadRules(isReload: true);
  }

  void clearFilters() {
    state = state.copyWith(
      searchName: '',
      clearParameterType: true,
      clearPlantId: true,
      clearStatus: true,
    );
    loadRules(isReload: true);
  }

  Future<bool> createRule(Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(ruleRepositoryProvider);
      await repository.createRule(data);
      state = state.copyWith(isProcessing: false);
      await loadRules(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateRule(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(ruleRepositoryProvider);
      await repository.updateRule(id, data);
      state = state.copyWith(isProcessing: false);
      await loadRules(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteRule(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(ruleRepositoryProvider);
      await repository.deleteRule(id);
      state = state.copyWith(isProcessing: false);
      await loadRules(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<RuleAutocompleteInfo>> searchRules(String query) async {
    try {
      final repository = ref.read(ruleRepositoryProvider);
      return await repository.searchRules(q: query);
    } catch (e) {
      return [];
    }
  }
}

final ruleApiProvider = Provider<RuleApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return RuleApi(client);
});

final ruleRepositoryProvider = Provider<RuleRepository>((ref) {
  final api = ref.watch(ruleApiProvider);
  return RuleRepositoryImpl(api);
});

final ruleProvider = NotifierProvider<RuleNotifier, RuleState>(
  RuleNotifier.new,
);
