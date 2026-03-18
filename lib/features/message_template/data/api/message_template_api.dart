import '../../presentation/model/message_template_model.dart';
import '../../../../core/network/api_client.dart';

class MessageTemplateApi {
  final ApiClient _client;

  MessageTemplateApi(this._client);

  Future<MessageTemplateResponse> getMessageTemplates({
    int page = 1,
    int limit = 10,
    String? name,
    int? status,
    int? isActive,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (name != null && name.isNotEmpty) {
      query['name'] = name;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (isActive != null) {
      query['is_active'] = isActive;
    }

    final response = await _client.get('/message-templates', query: query);
    return MessageTemplateResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<List<MessageTemplateAutocompleteInfo>> getMessageTemplateAutocomplete({
    String? q,
  }) async {
    final Map<String, dynamic> query = q != null ? {'q': q} : {};
    final response = await _client.get('/message-templates/search', query: query);
    final List data = response.data['data'] ?? [];
    return data
        .map(
          (e) => MessageTemplateAutocompleteInfo.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<void> createMessageTemplate(Map<String, dynamic> data) async {
    await _client.post('/message-templates', data: data);
  }

  Future<void> updateMessageTemplate(int id, Map<String, dynamic> data) async {
    await _client.put('/message-templates/$id', data: data);
  }

  Future<void> deleteMessageTemplate(int id) async {
    await _client.delete('/message-templates/$id');
  }

  Future<List<MessageTemplate>> getActiveTemplates() async {
    final response = await _client.get('/message-templates/active');
    final List data = response.data['data'] ?? [];
    return data
        .map(
          (e) => MessageTemplate.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }
}
