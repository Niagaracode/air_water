import '../../domain/repository/notification_repository.dart';
import '../../presentation/model/notification_model.dart';
import '../api/notification_api.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApi _api;

  NotificationRepositoryImpl(this._api);

  @override
  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) {
    return _api.getNotifications(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<NotificationSummary> getNotificationSummary() {
    return _api.getNotificationSummary();
  }

  @override
  Future<List<int>> downloadNotificationsExport({
    required String format,
    String? startDate,
    String? endDate,
    int? plantId,
    int? tankId,
    String? plantName,
    String? tankName,
    String? plantAddress,
  }) {
    return _api.downloadNotificationsExport(
      format: format,
      startDate: startDate,
      endDate: endDate,
      plantId: plantId,
      tankId: tankId,
      plantName: plantName,
      tankName: tankName,
      plantAddress: plantAddress,
    );
  }
}
