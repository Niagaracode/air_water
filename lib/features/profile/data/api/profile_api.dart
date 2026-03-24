import '../../../../core/network/api_client.dart';
import '../../presentation/model/profile_model.dart';

class ProfileApi {
  final ApiClient _client;

  ProfileApi(this._client);

  Future<ProfileModel> getProfile() async {
    final response = await _client.get('/me');
    return ProfileModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  Future<void> updateProfile(int userId, ProfileUpdateRequest request) async {
    await _client.put('/users/$userId', data: request.toJson());
  }

  Future<void> updateCompanyProfile(int companyId, Map<String, dynamic> data) async {
    await _client.put('/companies/$companyId', data: data);
  }
}
