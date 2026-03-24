import '../../presentation/model/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile();
  Future<void> updateProfile(int userId, ProfileUpdateRequest request);
  Future<void> updateCompanyProfile(int companyId, Map<String, dynamic> data);
}
