import '../../presentation/model/setting_model.dart';

abstract class SettingRepository {
  Future<SettingGroupResponse> getSettingsGrouped({
    int page = 1,
    int limit = 50,
    String? name,
    String? parameterType,
    int? plantId,
    int? isActive,
  });

  Future<SettingResponse> getSettings({
    int page = 1,
    int limit = 20,
    String? name,
    String? parameterType,
    int? plantId,
    int? isActive,
  });

  Future<void> createSetting(Map<String, dynamic> data);
  Future<void> updateSetting(int id, Map<String, dynamic> data);
  Future<void> deleteSetting(int id);
  Future<List<SettingAutocompleteInfo>> searchSettings({String? q});
  Future<List<Map<String, dynamic>>> getTemplatesByParameter(String parameterType);
}
