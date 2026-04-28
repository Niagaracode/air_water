import '../../../core/network/api_client.dart';

class DashboardApi {
  final ApiClient _client;

  DashboardApi(this._client);

  Future<List<dynamic>> getTankData() async {
    final res = await _client.get('/dashboard/tank-status');

    print('DATA: ${res.data}');

    final map = res.data as Map<String, dynamic>;
    return map['data'] as List<dynamic>;
  }
}