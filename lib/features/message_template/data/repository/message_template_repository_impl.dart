import '../../presentation/model/message_template_model.dart';
import '../../domain/repository/message_template_repository.dart';
import '../api/message_template_api.dart';

class MessageTemplateRepositoryImpl implements MessageTemplateRepository {
  final MessageTemplateApi _api;

  MessageTemplateRepositoryImpl(this._api);

  @override
  Future<MessageTemplateResponse> getMessageTemplates({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    int? isActive,
  }) {
    return _api.getMessageTemplates(
      page: page,
      limit: limit,
      name: name,
      status: status,
      isActive: isActive,
    );
  }

  @override
  Future<List<MessageTemplateAutocompleteInfo>> getMessageTemplateAutocomplete({
    String? q,
  }) {
    return _api.getMessageTemplateAutocomplete(q: q);
  }

  @override
  Future<void> createMessageTemplate(Map<String, dynamic> data) {
    return _api.createMessageTemplate(data);
  }

  @override
  Future<void> updateMessageTemplate(int id, Map<String, dynamic> data) {
    return _api.updateMessageTemplate(id, data);
  }

  @override
  Future<void> deleteMessageTemplate(int id) {
    return _api.deleteMessageTemplate(id);
  }

  @override
  Future<List<MessageTemplate>> getActiveTemplates() {
    return _api.getActiveTemplates();
  }

  @override
  Future<Map<String, dynamic>> getMessageTemplatePlaceholders() {
    return _api.getMessageTemplatesPlaceholders();
  }


}
