import 'dart:convert';
import '../../../core/network/http/api_service.dart';

class DashboardApi {
  final ApiService _client;

  DashboardApi(this._client);

  Future<List<dynamic>> getTankData() async {
    final res = await _client.get('/dashboard/site-info');
    final map = res.data as Map<String, dynamic>;
    print("Site Data: ${jsonEncode(map)}");
    return map['data'] as List<dynamic>;
  }
}