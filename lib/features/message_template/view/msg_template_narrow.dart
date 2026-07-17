import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme/app_theme.dart';
import '../presentation/controller/message_template_provider.dart';
import '../presentation/widgets/message_template_form.dart';
import '../presentation/model/message_template_model.dart';

class MsgTemplateNarrow extends ConsumerStatefulWidget {
  const MsgTemplateNarrow({super.key});

  @override
  ConsumerState<MsgTemplateNarrow> createState() => _MsgTemplateNarrowState();
}

class _MsgTemplateNarrowState extends ConsumerState<MsgTemplateNarrow> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(messageTemplateProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageTemplateProvider);
    final notifier = ref.read(messageTemplateProvider.notifier);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () => _showAddModal(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Template',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(state, notifier),
          Expanded(
            child: state.isLoading && state.templates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.templates.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Show loading indicator at the end
                if (state.hasMore && index == state.templates.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final template = state.templates[index];
                return _buildTemplateCard(template, notifier);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(MessageTemplateState state, MessageTemplateNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MESSAGE TEMPLATES',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Define and manage dynamic alarm and notification message templates.',
            style: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildSearchBar(notifier, state),
        ],
      ),
    );
  }

  Widget _buildSearchBar(MessageTemplateNotifier notifier, MessageTemplateState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search by template name...',
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty ? IconButton(
            icon: const Icon(
              Icons.clear,
              color: Colors.red,
              size: 18,
            ),
            onPressed: () {
              _searchController.clear();
              notifier.clearFilters();
            },
          ) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: (value) {
          notifier.setSearchName(value);
          notifier.loadTemplates(isReload: true);
        },
      ),
    );
  }

  Widget _buildTemplateCard(MessageTemplate template, MessageTemplateNotifier notifier) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showAddModal(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Subj : ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              TextSpan(
                                text: template.subject ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(template),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    TextSpan(
                      text: 'Body : ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    TextSpan(
                      text: template.body ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (template.description != null && template.description!.isNotEmpty)
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      TextSpan(
                        text: 'Desc : ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      TextSpan(
                        text: template.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddModal([MessageTemplate? template]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddMessageTemplate',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => MessageTemplateForm(initialTemplate: template, isNarrow: true,),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }

  void _confirmDelete(MessageTemplate template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(messageTemplateProvider.notifier).deleteTemplate(template.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template deleted')),
                );
                // Refresh the list
                ref.read(messageTemplateProvider.notifier).loadTemplates(isReload: true);
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}