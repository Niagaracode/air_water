import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/roaster_model.dart';
import '../../data/api/roaster_api.dart';
import '../../domain/repository/roaster_repository.dart';
import '../../data/repository/roaster_repository_impl.dart';
import '../../../../core/network/http/api_service.dart';

final roasterApiProvider = Provider(
  (ref) => RosterApi(ref.read(apiClientProvider)),
);

final roasterRepositoryProvider = Provider<RoasterRepository>(
  (ref) => RoasterRepositoryImpl(ref.read(roasterApiProvider)),
);

class RoasterState {
  final List<Roster> rosters;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final String searchName;
  final int page;
  final bool hasMore;
  final int totalEntries;

  RoasterState({
    this.rosters = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.searchName = '',
    this.page = 1,
    this.hasMore = true,
    this.totalEntries = 0,
  });

  RoasterState copyWith({
    List<Roster>? rosters,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    String? searchName,
    int? page,
    bool? hasMore,
    int? totalEntries,
  }) {
    return RoasterState(
      rosters: rosters ?? this.rosters,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      searchName: searchName ?? this.searchName,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
    );
  }
}

class RoasterNotifier extends Notifier<RoasterState> {
  static const int _limit = 50;

  @override
  RoasterState build() {
    ref.keepAlive();
    Future.microtask(() => loadRosters());
    return RoasterState();
  }

  Future<void> loadRosters({bool isReload = false}) async {
    if (state.isLoading) return;

    if (state.rosters.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final repository = ref.read(roasterRepositoryProvider);
      final response = await repository.getRoasters(
        page: 1,
        limit: _limit,
        search: state.searchName,
      );

      state = state.copyWith(
        rosters: response.data,
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
      final repository = ref.read(roasterRepositoryProvider);
      final response = await repository.getRoasters(
        page: nextPage,
        limit: _limit,
        search: state.searchName,
      );

      state = state.copyWith(
        rosters: [...state.rosters, ...response.data],
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

  Future<bool> createRoster(Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      await repository.createRoaster(data);
      await loadRosters(isReload: true);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateRoster(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      await repository.updateRoster(id, data);
      await loadRosters(isReload: true);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteRoaster(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(roasterRepositoryProvider);
      await repository.deleteRoaster(id);
      await loadRosters(isReload: true);
      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  // Member Management
  Future<bool> addMember(Map<String, dynamic> data) async {
    try {
       final repository = ref.read(roasterRepositoryProvider);
       await repository.addMember(data);
       return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMember(int memberId, Map<String, dynamic> data) async {
    try {
       final repository = ref.read(roasterRepositoryProvider);
       await repository.updateMember(memberId, data);
       return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeMember(int memberId) async {
    try {
       final repository = ref.read(roasterRepositoryProvider);
       await repository.removeMember(memberId);
       return true;
    } catch (e) {
      return false;
    }
  }

  Future<Roster?> getRosterDetail(int id) async {
    try {
       final repository = ref.read(roasterRepositoryProvider);
       return await repository.getRosterById(id);
    } catch (e) {
      return null;
    }
  }

  Future<List<RosterMember>> getRosterMembers(
    int rosterId, {
    String? q,
    int? roleId,
    int? status,
  }) async {
    try {
      final repository = ref.read(roasterRepositoryProvider);
      return await repository.getRosterMembers(
        rosterId,
        q: q,
        roleId: roleId,
        status: status,
      );
    } catch (e) {
      return [];
    }
  }








}

final roasterNotifierProvider = NotifierProvider<RoasterNotifier, RoasterState>(
  RoasterNotifier.new,
);
