import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/rule_model.dart';
import '../../data/api/rule_api.dart';
import '../../domain/repository/rule_repository.dart';
import '../../data/repository/rule_repository_impl.dart';
import '../../../../core/network/api_client.dart';

class RuleState {
  final List<Rule> rules;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final int totalEntries;
  final String searchName;
  final String? parameterType;

  RuleState({
    this.rules = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    this.totalEntries = 0,
    this.searchName = '',
    this.parameterType,
  });

  RuleState copyWith({
    List<Rule>? rules,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    int? totalEntries,
    String? searchName,
    String? parameterType,
  }) {
    return RuleState(
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
      searchName: searchName ?? this.searchName,
      parameterType: parameterType ?? this.parameterType,
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

    if (state.rules.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, page: 1, rules: []);
    }

    try {
      final repository = ref.read(ruleRepositoryProvider);
      final response = await repository.getRules(
        page: 1,
        limit: _limit,
        name: state.searchName,
        parameterType: state.parameterType,
      );

      if (timestamp != _lastRequestTimestamp) return;

      state = state.copyWith(
        rules: response.data,
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
      final response = await repository.getRules(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
        parameterType: state.parameterType,
      );

      if (timestamp != _lastRequestTimestamp) return;

      state = state.copyWith(
        rules: [...state.rules, ...response.data],
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

  void clearFilters() {
    state = state.copyWith(searchName: '', parameterType: null);
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
