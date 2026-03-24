import '../../domain/repository/profile_repository.dart';
import '../api/profile_api.dart';
import '../../presentation/model/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi _api;

  ProfileRepositoryImpl(this._api);

  @override
  Future<ProfileModel> getProfile() async {
    return await _api.getProfile();
  }

  @override
  Future<void> updateProfile(int userId, ProfileUpdateRequest request) async {
    await _api.updateProfile(userId, request);
  }

  @override
  Future<void> updateCompanyProfile(int companyId, Map<String, dynamic> data) async {
    await _api.updateCompanyProfile(companyId, data);
  }
}
