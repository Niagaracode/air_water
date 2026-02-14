
import '../../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<Map<String, dynamic>> login(String un, String pw,) async {
    final response = await _client.post(
      '/login',
      data: {
        'username': un,
        'password': pw,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}