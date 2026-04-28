import '../../../core/network/api_client.dart';
import '../presentation/model/tank_data_model.dart';

class DashboardApi {
  final ApiClient _client;

  DashboardApi(this._client);

  Future<List<TankDataModel>> getTankStatus() async {
    final response = await _client.get('/dashboard/tank-status');
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => TankDataModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch tank status');
    }
  }
}
