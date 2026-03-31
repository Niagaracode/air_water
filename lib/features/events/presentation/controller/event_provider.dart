import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/event_model.dart';
import '../../data/api/event_api.dart';

class EventState {
  final List<EventLog> logs;
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;
  final int total;

  EventState({
    required this.logs,
    required this.isLoading,
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
  });

  EventState copyWith({
    List<EventLog>? logs,
    bool? isLoading,
    String? error,
    int? page,
    int? totalPages,
    int? total,
  }) {
    return EventState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
    );
  }
}

class EventNotifier extends Notifier<EventState> {
  @override
  EventState build() {
    return EventState(logs: [], isLoading: false);
  }

  Future<void> loadLogs({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(page: 1, logs: [], isLoading: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final api = ref.read(eventApiProvider);
      final response = await api.getLogs(page: state.page);

      state = state.copyWith(
        isLoading: false,
        logs: refresh ? response.data : [...state.logs, ...response.data],
        totalPages: response.pagination.totalPages,
        total: response.pagination.total,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void loadMore() {
    if (state.page < state.totalPages && !state.isLoading) {
      state = state.copyWith(page: state.page + 1);
      loadLogs();
    }
  }
}

final eventProvider = NotifierProvider<EventNotifier, EventState>(
  EventNotifier.new,
);
