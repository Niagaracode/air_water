import '../../data/api/setting_api.dart';
import '../../presentation/model/setting_model.dart';
import '../../domain/repository/setting_repository.dart';

class SettingRepositoryImpl implements SettingRepository {
  final SettingApi _api;

  SettingRepositoryImpl(this._api);

  @override
  Future<SettingGroupResponse> getSettingsGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? parameterType,
    int? plantId,
    int? tankId,
    int? isActive,
  }) {
    return _api.getSettingsGrouped(
      page: page,
      limit: limit,
      name: name,
      parameterType: parameterType,
      plantId: plantId,
      tankId: tankId,
      isActive: isActive,
    );
  }

  @override
  Future<SettingResponse> getSettings({
    int page = 1,
    int limit = 20,
    String? name,
    String? parameterType,
    int? plantId,
    int? tankId,
    int? isActive,
  }) {
    return _api.getSettings(
      page: page,
      limit: limit,
      name: name,
      parameterType: parameterType,
      plantId: plantId,
      tankId: tankId,
      isActive: isActive,
    );
  }

  @override
  Future<void> createSetting(Map<String, dynamic> data) => _api.createSetting(data);

  @override
  Future<void> updateSetting(int id, Map<String, dynamic> data) => _api.updateSetting(id, data);

  @override
  Future<void> deleteSetting(int id) => _api.deleteSetting(id);

  @override
  Future<List<SettingAutocompleteInfo>> searchSettings({String? q}) => _api.searchSettings(q: q);

  @override
  Future<List<Map<String, dynamic>>> getTemplatesByParameter(String parameterType) =>
      _api.getTemplatesByParameter(parameterType);
}
