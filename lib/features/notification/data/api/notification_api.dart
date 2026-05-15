import '../../presentation/model/notification_model.dart';
import '../../../../core/network/http/api_service.dart';

class NotificationApi {
  final ApiService _client;

  NotificationApi(this._client);

  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    final response = await _client.get('/notifications', query: query);
    return NotificationResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<NotificationSummary> getNotificationSummary() async {
    final response = await _client.get('/notifications/summary');
    return NotificationSummary.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }
}
