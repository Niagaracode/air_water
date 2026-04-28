import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/message_template_model.dart';
import '../../data/api/message_template_api.dart';
import '../../domain/repository/message_template_repository.dart';
import '../../data/repository/message_template_repository_impl.dart';
import '../../../../core/network/api_client.dart';

class MessageTemplateState {
  final List<MessageTemplate> templates;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final int page;
  final bool hasMore;
  final int totalEntries;
  final String searchName;

  MessageTemplateState({
    this.templates = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.page = 1,
    this.hasMore = false,
    this.totalEntries = 0,
    this.searchName = '',
  });

  MessageTemplateState copyWith({
    List<MessageTemplate>? templates,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    int? page,
    bool? hasMore,
    int? totalEntries,
    String? searchName,
  }) {
    return MessageTemplateState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalEntries: totalEntries ?? this.totalEntries,
      searchName: searchName ?? this.searchName,
    );
  }
}

class MessageTemplateNotifier extends Notifier<MessageTemplateState> {
  static const int _limit = 50;
  int _lastRequestTimestamp = 0;

  @override
  MessageTemplateState build() {
    ref.keepAlive();
    Future.microtask(() => loadTemplates());
    return MessageTemplateState();
  }

  Future<void> loadTemplates({bool isReload = false}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    if (state.templates.isEmpty || isReload) {
      state = state.copyWith(isLoading: true, page: 1, templates: []);
    }

    try {
      final repository = ref.read(messageTemplateRepositoryProvider);
      final response = await repository.getMessageTemplates(
        page: 1,
        limit: _limit,
        name: state.searchName,
      );

      if (timestamp != _lastRequestTimestamp) return;

      state = state.copyWith(
        templates: response.data,
        isLoading: false,
        totalEntries: response.pagination.total,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: 1,
      );
    } catch (e) {
      if (timestamp != _lastRequestTimestamp) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _lastRequestTimestamp = timestamp;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final repository = ref.read(messageTemplateRepositoryProvider);
      final response = await repository.getMessageTemplates(
        page: nextPage,
        limit: _limit,
        name: state.searchName,
      );

      if (timestamp != _lastRequestTimestamp) return;

      state = state.copyWith(
        templates: [...state.templates, ...response.data],
        isLoading: false,
        hasMore: response.pagination.page < response.pagination.totalPages,
        page: nextPage,
      );
    } catch (e) {
      if (timestamp != _lastRequestTimestamp) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchName(String name) {
    state = state.copyWith(searchName: name);
  }

  void clearFilters() {
    state = state.copyWith(searchName: '');
    loadTemplates(isReload: true);
  }

  Future<bool> createTemplate(Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(messageTemplateRepositoryProvider);
      await repository.createMessageTemplate(data);
      state = state.copyWith(isProcessing: false);
      await loadTemplates(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateTemplate(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(messageTemplateRepositoryProvider);
      await repository.updateMessageTemplate(id, data);
      state = state.copyWith(isProcessing: false);
      await loadTemplates(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTemplate(int id) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final repository = ref.read(messageTemplateRepositoryProvider);
      await repository.deleteMessageTemplate(id);
      state = state.copyWith(isProcessing: false);
      await loadTemplates(isReload: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<List<MessageTemplateAutocompleteInfo>> searchTemplates(String query) async {
    try {
      final repository = ref.read(messageTemplateRepositoryProvider);
      return await repository.getMessageTemplateAutocomplete(q: query);
    } catch (e) {
      return [];
    }
  }
}

final messageTemplateApiProvider = Provider<MessageTemplateApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return MessageTemplateApi(client);
});

final messageTemplateRepositoryProvider = Provider<MessageTemplateRepository>((ref) {
  final api = ref.watch(messageTemplateApiProvider);
  return MessageTemplateRepositoryImpl(api);
});

final messageTemplateProvider = NotifierProvider<MessageTemplateNotifier, MessageTemplateState>(
  MessageTemplateNotifier.new,
);

final activeTemplatesProvider = FutureProvider<List<MessageTemplate>>((ref) {
  final repo = ref.watch(messageTemplateRepositoryProvider);
  return repo.getActiveTemplates();
});
