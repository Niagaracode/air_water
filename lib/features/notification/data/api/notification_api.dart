import '../../presentation/model/notification_model.dart';
import '../../../../core/network/http/api_service.dart';

class NotificationApi {
  final ApiService _client;

  NotificationApi(this._client);

  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };
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

  Future<List<int>> downloadNotificationsExport({
    required String format,
    String? startDate,
    String? endDate,
    int? plantId,
    int? tankId,
    String? plantName,
    String? tankName,
    String? plantAddress,
  }) async {
    final Map<String, dynamic> query = {
      'format': format,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (plantId != null) 'plantId': plantId.toString(),
      if (tankId != null) 'tankId': tankId.toString(),
      if (plantName != null) 'plantName': plantName,
      if (tankName != null) 'tankName': tankName,
      if (plantAddress != null) 'plantAddress': plantAddress,
    };
    final response = await _client.download('/notifications/export', query: query);
    return List<int>.from(response.data);
  }
}
