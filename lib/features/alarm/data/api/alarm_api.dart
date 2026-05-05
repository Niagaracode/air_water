import '../../../../core/network/http/api_service.dart';
import '../../presentation/model/alarm_model.dart';

class AlarmApi {
  final ApiService _client;

  AlarmApi(this._client);

  Future<AlarmResponse> getAlarms({int page = 1, int limit = 50}) async {
    final response = await _client.get('/alarms', query: {
      'page': page,
      'limit': limit,
    });
    
    return AlarmResponse.fromJson(response.data);
  }
}
