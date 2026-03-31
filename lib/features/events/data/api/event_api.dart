import '../../../../core/network/api_client.dart';
import '../../presentation/model/event_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventApi {
  final ApiClient _client;

  EventApi(this._client);

  Future<EventResponse> getLogs({
    int page = 1,
    int? limit,
    int? userId,
    String? action,
    String? module,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      if (limit != null) 'limit': limit,
      if (userId != null) 'user_id': userId,
      if (action != null && action.isNotEmpty) 'action': action,
      if (module != null && module.isNotEmpty) 'module': module,
    };

    final response = await _client.get('/activity-logs', query: query);
    return EventResponse.fromJson(response.data);
  }
}

final eventApiProvider = Provider<EventApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return EventApi(client);
});
