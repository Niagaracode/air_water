import '../../presentation/model/message_template_model.dart';

abstract class MessageTemplateRepository {

  Future<MessageTemplateResponse> getMessageTemplates({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    int? isActive,
  });

  Future<List<MessageTemplateAutocompleteInfo>> getMessageTemplateAutocomplete({String? q});

  Future<Map<String, dynamic>> getMessageTemplatePlaceholders();

  Future<void> createMessageTemplate(Map<String, dynamic> data);

  Future<void> updateMessageTemplate(int id, Map<String, dynamic> data);

  Future<void> deleteMessageTemplate(int id);

  Future<List<MessageTemplate>> getActiveTemplates();
}
