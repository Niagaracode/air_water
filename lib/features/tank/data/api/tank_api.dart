import 'package:dio/dio.dart';
import '../../presentation/model/tank_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../../../core/network/api_client.dart';

class TankApi {
  final ApiClient _client;

  TankApi(this._client);

  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? plantName,
    String? tankName,
    int? status,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (plantName != null && plantName.isNotEmpty) {
      query['plant_name'] = plantName;
    }
    if (tankName != null && tankName.isNotEmpty) {
      query['tank_number'] = tankName;
    }
    if (status != null) {
      query['status'] = status;
    }

    final response = await _client.get('/tanks/grouped', query: query);
    return TankGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<PlantAutocompleteInfo>> getPlantsForTankAutocomplete({
    String? q,
  }) async {
    final Map<String, dynamic> query = {};
    if (q != null && q.isNotEmpty) {
      query['q'] = q;
    }
    final response = await _client.get(
      '/plants/tank-autocomplete',
      query: query,
    );
    return (response.data['data'] as List)
        .map((i) => PlantAutocompleteInfo.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTank(TankCreateRequest request) async {
    if (request.imageFile != null) {
      final bytes = await request.imageFile!.readAsBytes();
      final formData = FormData.fromMap({
        ...request.toJson(),
        'tank_image': MultipartFile.fromBytes(
          bytes,
          filename: request.imageFile!.name,
        ),
      });
      await _client.post('/tanks', data: formData);
    } else {
      await _client.post('/tanks', data: request.toJson());
    }
  }

  Future<void> updateTank(int id, TankCreateRequest request) async {
    if (request.imageFile != null) {
      final bytes = await request.imageFile!.readAsBytes();
      final formData = FormData.fromMap({
        ...request.toJson(),
        'tank_image': MultipartFile.fromBytes(
          bytes,
          filename: request.imageFile!.name,
        ),
      });
      await _client.put('/tanks/$id', data: formData);
    } else {
      await _client.put('/tanks/$id', data: request.toJson());
    }
  }

  Future<void> deleteTank(int id) async {
    await _client.delete('/tanks/$id');
  }

  Future<Map<String, dynamic>> getTankDropdowns() async {
    final response = await _client.get('/tanks/dropdowns');
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<List<String>> getTankNameSuggestions({String? q}) async {
    final Map<String, dynamic> query = {};
    if (q != null && q.isNotEmpty) {
      query['q'] = q;
    }
    final response = await _client.get(
      '/tanks/autocomplete-names',
      query: query,
    );
    return (response.data['data'] as List).map((i) => i.toString()).toList();
  }

  Future<List<TankProduct>> getProducts() async {
    final response = await _client.get('/products');
    return (response.data['data'] as List)
        .map((i) => TankProduct.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<List<Tank>> getTanks({int? plantId}) async {
    final Map<String, dynamic> query = {};
    if (plantId != null) {
      query['plant_id'] = plantId;
    }
    final response = await _client.get('/tanks', query: query);
    final List data = response.data['data'] ?? [];
    return data.map((i) => Tank.fromJson(i as Map<String, dynamic>)).toList();
  }
}
