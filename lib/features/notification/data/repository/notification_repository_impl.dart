import '../../domain/repository/notification_repository.dart';
import '../../presentation/model/notification_model.dart';
import '../api/notification_api.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApi _api;

  NotificationRepositoryImpl(this._api);

  @override
  Future<NotificationResponse> getNotifications({int page = 1, int limit = 50}) {
    return _api.getNotifications(page: page, limit: limit);
  }

  @override
  Future<NotificationSummary> getNotificationSummary() {
    return _api.getNotificationSummary();
  }
}
