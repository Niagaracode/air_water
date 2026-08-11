import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../site/presentation/model/site_model.dart';
import '../../../core/network/http/api_service.dart';
import 'model/sent_and_received_model.dart';
import 'model/tank_channel_model.dart';
import 'model/tank_event_model.dart';
import 'model/tank_model.dart';
import 'model/tank_rule_model.dart';

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

    debugPrint(jsonEncode(response.data));

    return TankGroupedResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<SiteAutocompleteInfo>> getSitesForTankAutocomplete({
    String? q,
    int? companyId,
  }) async {
    final Map<String, dynamic> query = {};
    if (q != null && q.isNotEmpty) {
      query['q'] = q;
    }
    if (companyId != null) {
      query['company_id'] = companyId;
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
    await _client.post('/tanks', data: request.toJson());
  }

  Future<void> updateTank(int id, TankCreateRequest request) async {
    await _client.put('/tanks/$id', data: request.toJson());
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

  Future<Map<String, dynamic>> getTankReadings({
    required int tankId,
    String? day,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/devices/$tankId/graph';

    final queryParams = <String>[];

    if (day != null) {
      queryParams.add('date=$day');
    }

    if (startDate != null) {
      queryParams.add(
        'startDate=${startDate.toIso8601String()}',
      );
    }

    if (endDate != null) {
      queryParams.add(
        'endDate=${endDate.toIso8601String()}',
      );
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final response = await _client.get(url);

    return response.data;
  }



  Future<List<TankEventModel>> getTankEvents(int tankId, String day) async {
    final response = await _client.get('/tank/$tankId/events?day=$day');
    final List data = response.data['data'] ?? [];
    return data.map((e) => TankEventModel.fromJson(e)).toList();
  }

  Future<List<TankRuleModel>> getAllTankRules() async {
    final response = await _client.get('/rules/all');
    final List data = response.data['data'] ?? [];
    return data.map((e) => TankRuleModel.fromJson(e)).toList();
  }

  Future<List<TankChannelModel>> getTankChannels(int tankId) async {
    final response = await _client.get('/tank/$tankId/channels');
    final List data = response.data['data']['channel'] ?? [];
    return data.map((e) => TankChannelModel.fromJson(e)).toList();
  }

  Future<void> updateTankEvent(int tankId, Map<String, dynamic> data) async {
    await _client.put('/tank/$tankId/channel_events', data: data);
  }

  Future<List<SentAndReceivedModel>> getTankSentAndReceived(int tankId) async {
    final response = await _client.get('/tank/$tankId/send_and_receive');
    final List data = response.data['data']['send_receive'] ?? [];
    return data.map((e) => SentAndReceivedModel.fromJson(e)).toList();
  }

}
