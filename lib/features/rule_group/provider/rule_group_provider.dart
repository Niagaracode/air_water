import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/http/api_service.dart';

import '../data/api/rule_group_api.dart';
import '../data/repository/rule_group_repository.dart';
import '../data/repository/rule_group_repository_impl.dart';

import '../model/rule_group_model.dart';

class RuleGroupState {

  final List<RuleGroupModel> ruleGroups;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final int totalEntries;
  final String searchName;

  RuleGroupState({
    this.ruleGroups = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    this.totalEntries = 0,
    this.searchName = '',
  });

  RuleGroupState copyWith({
    List<RuleGroupModel>? ruleGroups,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    int? totalEntries,
    String? searchName,
  }) {

    return RuleGroupState(
      ruleGroups: ruleGroups ?? this.ruleGroups,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
      searchName: searchName ?? this.searchName,
    );
  }
}

class RuleGroupNotifier extends Notifier<RuleGroupState> {

  static const int _limit = 50;
  int _lastRequestTimestamp = 0;

  @override
  RuleGroupState build() {

    ref.keepAlive();
    Future.microtask(() => loadRuleGroups());
    return RuleGroupState();
  }

  /// LOAD RULE GROUPS
  Future<void> loadRuleGroups({bool isReload = false}) async {

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    state = state.copyWith(isLoading: true, page: 1, ruleGroups: []);

    try {
      final repository = ref.read(ruleGroupRepositoryProvider);

      final response = await repository.getRuleGroup(
        page: 1,
        limit: _limit,
        name: state.searchName,
      );

      if (timestamp != _lastRequestTimestamp) {
        return;
      }

      state = state.copyWith(
        ruleGroups: response.data,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
      );

    } catch (e) {

      if (timestamp != _lastRequestTimestamp) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// LOAD MORE
  Future<void> loadMoreRuleGroups() async {

    if (state.isLoading || !state.hasMore) {
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;
    state = state.copyWith(
      isLoading: true,
    );

    try {

      final nextPage = state.page + 1;
      final repository = ref.read(ruleGroupRepositoryProvider);
      final response = await repository.getRuleGroup(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
      );

      print('getRuleGroup:$response');

      if (timestamp != _lastRequestTimestamp) {
        return;
      }

      state = state.copyWith(ruleGroups: [
          ...state.ruleGroups,
          ...response.data,
        ],
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );

    } catch (e) {

      if (timestamp != _lastRequestTimestamp) {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// SEARCH
  void setSearchName(String name) {

    state = state.copyWith(
      searchName: name,
    );
  }

  /// CLEAR FILTER
  void clearFilters() {

    state = state.copyWith(
      searchName: '',
    );

    loadRuleGroups(isReload: true);
  }

  /// CREATE
  Future<bool> createRuleGroup(
      Map<String, dynamic> data,
      ) async {

    state = state.copyWith(
      isProcessing: true,
      error: null,
    );

    try {

      final repository = ref.read(ruleGroupRepositoryProvider);
      await repository.createRuleGroup(data);
      state = state.copyWith(isProcessing: false);
      await loadRuleGroups(isReload: true);
      return true;

    } catch (e) {

      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );

      return false;
    }
  }

  /// UPDATE
  Future<bool> updateRuleGroup(int id, Map<String, dynamic> data) async {

    state = state.copyWith(
      isProcessing: true,
      error: null,
    );

    try {

      final repository = ref.read(ruleGroupRepositoryProvider);
      await repository.updateRuleGroup(id, data);
      state = state.copyWith(isProcessing: false);
      await loadRuleGroups(isReload: true);

      return true;

    } catch (e) {

      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  /// DELETE
  Future<bool> deleteRuleGroup(int id) async {

    state = state.copyWith(
      isProcessing: true,
      error: null,
    );

    try {

      final repository = ref.read(ruleGroupRepositoryProvider);
      await repository.deleteRuleGroup(id);
      state = state.copyWith(isProcessing: false);
      await loadRuleGroups(isReload: true);

      return true;

    } catch (e) {

      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );

      return false;
    }
  }
}

final ruleGroupApiProvider = Provider<RuleGroupApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return RuleGroupApi(client);
});

final ruleGroupRepositoryProvider = Provider<RuleGroupRepository>((ref) {
  final api = ref.watch(ruleGroupApiProvider);
  return RuleGroupRepositoryImpl(api);
});

final ruleGroupProvider = NotifierProvider<RuleGroupNotifier, RuleGroupState>(
  RuleGroupNotifier.new,
);