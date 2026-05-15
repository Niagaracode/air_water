import '../../presentation/model/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationResponse> getNotifications({int page = 1, int limit = 50});
  Future<NotificationSummary> getNotificationSummary();
}
