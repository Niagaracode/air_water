import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import '../../../shared/widgets/app_table.dart';
import '../../../shared/widgets/table_data_cell.dart';
import '../../../shared/widgets/table_header_cell.dart';
import '../presentation/controller/message_template_provider.dart';
import '../presentation/widgets/message_template_form.dart';
import '../presentation/model/message_template_model.dart';

class MsgTemplateWide extends ConsumerStatefulWidget {
  const MsgTemplateWide({super.key});

  @override
  ConsumerState<MsgTemplateWide> createState() => _MsgTemplateWideState();
}

class _MsgTemplateWideState extends ConsumerState<MsgTemplateWide> {
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
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      body: Column(
        children: [
          _buildHeader(state, notifier),
          if (!state.isLoading || state.templates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildTableBody(state, notifier),
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(MessageTemplateState state, MessageTemplateNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      margin: const EdgeInsets.only(left: 26, right: 26, top: 26, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                    style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddModal(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'CREATE TEMPLATE',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterRow(notifier, state),
        ],
      ),
    );
  }

  Widget _buildFilterRow(MessageTemplateNotifier notifier, MessageTemplateState state) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: RawAutocomplete<MessageTemplateAutocompleteInfo>(
            textEditingController: _searchController,
            focusNode: _focusNode,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<MessageTemplateAutocompleteInfo>.empty();
              }
              return await notifier.searchTemplates(textEditingValue.text);
            },
            displayStringForOption: (MessageTemplateAutocompleteInfo option) => option.name,
            onSelected: (MessageTemplateAutocompleteInfo selection) {
              _searchController.text = selection.name;
              notifier.setSearchName(selection.name);
              notifier.loadTemplates(isReload: true);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return AppTextField(
                controller: controller,
                focusNode: focusNode,
                hint: 'Search By Name',
                onSubmitted: (v) {
                  _searchController.text = v;
                  notifier.setSearchName(v);
                  notifier.loadTemplates(isReload: true);
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 400,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: option.description != null
                              ? Text(option.description!, style: GoogleFonts.inter(fontSize: 12))
                              : null,
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        AppClearButton(
          onPressed: () {
            _searchController.clear();
            notifier.clearFilters();
          },
        ),
        const Expanded(flex: 1, child: SizedBox()),
      ],
    );
  }


  Widget _buildTableBody(MessageTemplateState state, MessageTemplateNotifier notifier) {

    if (state.templates.isEmpty && !state.isLoading) {
      return const AppTableEmptyState(icon: Icons.message_outlined, title: 'No templates found');
    }

    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: (state.templates.length * 45) + 50,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
          border: Border(
            left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          )
      ),
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 1000,
        dataRowHeight: 45,
        headingRowHeight: 45,
        headingRowColor: WidgetStateProperty.all(Colors.black38),
        columns: [
          DataColumn2(
            label: Center(child: TableHeaderCell(label: 'SI.NO')),
            fixedWidth: 70,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'Template Name'),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'Subject'),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: TableHeaderCell(label: 'Description'),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: Center(child: TableHeaderCell(label: 'Actions')),
            fixedWidth: 100,
          ),
        ],
        rows: List<DataRow>.generate(state.templates.length + (state.hasMore ? 1 : 0), (index) {
          if (state.hasMore && index == state.templates.length) {
            return const DataRow(
              cells: [
                DataCell(Center(child: CircularProgressIndicator())),
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
                DataCell(Text('')),
              ],
            );
          }

          final template = state.templates[index];

          return DataRow(
            cells: [
              DataCell(Center(child: TableDataCell(label: '${index + 1}'))),
              DataCell(TableDataCell(label: template.name)),
              DataCell(TableDataCell(label: '${template.subject}')),
              DataCell(TableDataCell(label: '${template.description}')),
              DataCell(Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTableActionButton(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                    onTap: () => _showAddModal(template),
                  ),
                  const SizedBox(width: 12),
                  AppTableActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEF2F2),
                    onTap: () => _confirmDelete(template),
                  ),
                ],
              )),
            ],
          );
        }),
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
      pageBuilder: (context, anim1, anim2) => MessageTemplateForm(initialTemplate: template),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(messageTemplateProvider.notifier).deleteTemplate(template.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template deleted')));
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

}