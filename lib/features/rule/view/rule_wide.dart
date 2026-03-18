import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import '../presentation/controller/rule_provider.dart';
import '../presentation/widgets/add_rule_modal.dart';
import '../presentation/model/rule_model.dart';

class RuleWide extends ConsumerStatefulWidget {
  const RuleWide({super.key});

  @override
  ConsumerState<RuleWide> createState() => _RuleWideState();
}

class _RuleWideState extends ConsumerState<RuleWide> {
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
      ref.read(ruleProvider.notifier).loadMore();
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
    final state = ref.watch(ruleProvider);
    final notifier = ref.read(ruleProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeader(state, notifier),
                if (!state.isLoading || state.rules.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTableHeader(),
                        _buildTableBody(state, notifier),
                      ],
                    ),
                  ),
                const SizedBox(height: 48),
              ],
            ),
          ),
          if (state.isProcessing) const AppLoader(message: 'Processing...'),
        ],
      ),
    );
  }

  Widget _buildHeader(RuleState state, RuleNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
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
                    'RULES MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Define and manage alarm conditions and automated notification rules.',
                    style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddModal(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'CREATE RULE',
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.totalEntries} entries',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(RuleNotifier notifier, RuleState state) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: RawAutocomplete<RuleAutocompleteInfo>(
            textEditingController: _searchController,
            focusNode: _focusNode,
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<RuleAutocompleteInfo>.empty();
              }
              return await notifier.searchRules(textEditingValue.text);
            },
            displayStringForOption: (RuleAutocompleteInfo option) => option.name,
            onSelected: (RuleAutocompleteInfo selection) {
              _searchController.text = selection.name;
              notifier.setSearchName(selection.name);
              notifier.loadRules(isReload: true);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return AppTextField(
                controller: controller,
                focusNode: focusNode,
                hint: 'Search By Name',
                onSubmitted: (v) {
                  _searchController.text = v;
                  notifier.setSearchName(v);
                  notifier.loadRules(isReload: true);
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 50),
          const SizedBox(width: 16),
          AppTableHeaderCell('Rule Name', flex: 4),
          const SizedBox(width: 16),
          AppTableHeaderCell('Parameter', flex: 2),
          const SizedBox(width: 16),
          AppTableHeaderCell('Condition', flex: 3),
          const SizedBox(width: 16),
          AppTableHeaderCell('Template', flex: 4),
          const SizedBox(width: 16),
          AppTableHeaderCell('Status', flex: 2),
          const SizedBox(width: 16),
          AppTableHeaderCell('Actions', width: 110),
        ],
      ),
    );
  }

  Widget _buildTableBody(RuleState state, RuleNotifier notifier) {
    if (state.rules.isEmpty && !state.isLoading) {
      return const AppTableEmptyState(icon: Icons.gavel_rounded, title: 'No rules found');
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        border: Border(
           left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
           right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
           bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        )
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.rules.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
        itemBuilder: (context, index) {
          if (index == state.rules.length) {
            return const AppTableLoadingMore();
          }

          final r = state.rules[index];
          final conditionText = r.conditionType == 'BETWEEN' 
              ? '${r.threshold1} to ${r.threshold2}' 
              : '${r.conditionType} ${r.threshold1}';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                AppTableCell((index + 1).toString().padLeft(2, '0'), width: 50),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Text(
                    r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Text(
                    r.parameterType ?? '—',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conditionText,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (r.statusLabel != null)
                        Text(
                          r.statusLabel!,
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Text(
                    r.templateName ?? '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF141E7A), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: Center(child: AppStatusBadge(status: r.isActive))),
                const SizedBox(width: 16),
                SizedBox(
                  width: 110,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppTableActionButton(
                        icon: Icons.edit_outlined,
                        color: const Color(0xFF2563EB),
                        bg: const Color(0xFFEFF6FF),
                        onTap: () => _showAddModal(r),
                      ),
                      const SizedBox(width: 12),
                      AppTableActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFDC2626),
                        bg: const Color(0xFFFEF2F2),
                        onTap: () => _confirmDelete(r),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddModal([Rule? rule]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddRule',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AddRuleModal(initialRule: rule),
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

  void _confirmDelete(Rule rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete rule "${rule.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(ruleProvider.notifier).deleteRule(rule.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rule deleted')));
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}