import '../../../core/network/http/api_service.dart';
import 'tank_dimension_model.dart';

class TankDimensionApi {
  final ApiService _client;
  TankDimensionApi(this._client);

  /// GET TANK DIMENSIONS
  Future<List<TankDimension>> getTankDimensions() async {
    final res = await _client.get('/tank-dimensions');
    final map = res.data as Map<String, dynamic>;
    final list = map['data'] as List<dynamic>;
    return list.map((e) => TankDimension.fromJson(e)).toList();
  }

  /// CREATE TANK DIMENSION
  Future<TankDimension> createTankDimension(Map<String, dynamic> data) async {
    final res = await _client.post('/tank-dimensions', data: data);
    final response = res.data['data'];
    return TankDimension.fromJson(response);
  }

  /// UPDATE TANK DIMENSION
  Future<TankDimension> updateTankDimension(int id, Map<String, dynamic> data) async {
    final res = await _client.put('/tank-dimensions/$id', data: data);
    final response = res.data['data'];
    return TankDimension.fromJson(response);
  }

  /// DELETE TANK DIMENSION
  Future<void> deleteTankDimension(int id) async {
    await _client.delete('/tank-dimensions/$id');
  }
}
