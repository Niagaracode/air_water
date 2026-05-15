import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/notification_model.dart';
import '../../data/api/notification_api.dart';
import '../../domain/repository/notification_repository.dart';
import '../../data/repository/notification_repository_impl.dart';
import '../../../../core/network/http/api_service.dart';

final notificationApiProvider = Provider(
  (ref) => NotificationApi(ref.read(apiClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(ref.read(notificationApiProvider)),
);

class NotificationState {
  final List<NotificationModel> notifications;
  final NotificationSummary summary;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  NotificationState({
    this.notifications = const [],
    required this.summary,
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    NotificationSummary? summary,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    Future.microtask(() => loadInitialData());
    return NotificationState(summary: NotificationSummary.empty());
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final summary = await repository.getNotificationSummary();
      final response = await repository.getNotifications(page: 1);

      state = state.copyWith(
        notifications: response.data,
        summary: summary,
        isLoading: false,
        page: 1,
        hasMore: response.pagination.page < response.pagination.totalPages,
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
      final repository = ref.read(notificationRepositoryProvider);
      final response = await repository.getNotifications(page: nextPage);

      state = state.copyWith(
        notifications: [...state.notifications, ...response.data],
        isLoading: false,
        page: nextPage,
        hasMore: response.pagination.page < response.pagination.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadInitialData();
}

final notificationNotifierProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
