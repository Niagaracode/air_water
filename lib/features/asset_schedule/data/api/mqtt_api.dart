import '../../../../core/network/http/api_service.dart';

class MqttApi {
  final ApiService _client;

  MqttApi(this._client);

  Future<Map<String, dynamic>> getDeviceHistory(String deviceId, {int days = 14}) async {
    final response = await _client.get('/mqtt/history', query: {
      'device_id': deviceId,
      'days': days,
    });
    return Map<String, dynamic>.from(response.data['data']);
  }
}
