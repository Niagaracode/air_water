
import '../../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<Map<String, dynamic>> login(
      String username,
      String password,
      ) async {
    final response = await _client.post(
      'login',
      data: {
        'username': username,
        'password': password,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }
}