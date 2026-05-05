import 'dart:convert';
import 'package:dio/dio.dart';
import '../../presentation/model/tank_model.dart';
import '../../../site/presentation/model/site_model.dart';
import '../../../../core/network/http/api_service.dart';

class TankApi {
  final ApiService _client;

  TankApi(this._client);

  Future<TankGroupedResponse> getTanksGrouped({
    int page = 1,
    int limit = 50,
    String? siteName,
    String? tankName,
    int? status,
    List<int>? companyIds,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (siteName != null && siteName.isNotEmpty) {
      query['plant_name'] = siteName;
    }
    if (tankName != null && tankName.isNotEmpty) {
      query['tank_number'] = tankName;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (companyIds != null && companyIds.isNotEmpty) {
      query['company_ids'] = companyIds;
    }

    final response = await _client.get('/tanks/grouped', query: query);
    return TankGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<SiteAutocompleteInfo>> getSitesForTankAutocomplete({
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
        .map((i) => SiteAutocompleteInfo.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTank(TankCreateRequest request) async {
    if (request.imageFile != null) {
      final bytes = await request.imageFile!.readAsBytes();
      final jsonRequest = request.toJson();
      if (jsonRequest['strapping_points'] != null) {
        jsonRequest['strapping_points'] = jsonEncode(jsonRequest['strapping_points']);
      }

      final formData = FormData.fromMap({
        ...jsonRequest,
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
      final jsonRequest = request.toJson();
      if (jsonRequest['strapping_points'] != null) {
        jsonRequest['strapping_points'] = jsonEncode(jsonRequest['strapping_points']);
      }

      final formData = FormData.fromMap({
        ...jsonRequest,
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

  Future<List<Tank>> getTanks({int? siteId}) async {
    final Map<String, dynamic> query = {};
    if (siteId != null) {
      query['plant_id'] = siteId;
    }
    final response = await _client.get('/tanks', query: query);
    final List data = response.data['data'] ?? [];
    return data.map((i) => Tank.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<Tank> getTankById(int id) async {
    final response = await _client.get('/tanks/$id');
    return Tank.fromJson(Map<String, dynamic>.from(response.data['data']));
  }
}
