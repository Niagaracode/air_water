import '../../presentation/model/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  });
  Future<NotificationSummary> getNotificationSummary();
  Future<List<int>> downloadNotificationsExport({
    required String format,
    String? startDate,
    String? endDate,
    int? plantId,
    int? tankId,
    String? plantName,
    String? tankName,
    String? plantAddress,
  });
}
