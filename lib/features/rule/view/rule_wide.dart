import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import '../../../../shared/widgets/app_autocomplete.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../plant/presentation/controller/plant_provider.dart';
import '../../plant/presentation/model/plant_model.dart' show PlantAutocompleteInfo;
import '../presentation/controller/rule_provider.dart';
import '../presentation/widgets/add_rule_modal.dart';
import '../presentation/model/rule_model.dart';

class RuleWide extends ConsumerStatefulWidget {
  const RuleWide({super.key});

  @override
  ConsumerState<RuleWide> createState() => _RuleWideState();
}

class _RuleWideState extends ConsumerState<RuleWide> {
  final _ruleAutocompleteController = TextEditingController();
  final _plantAutocompleteController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(ruleProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _ruleAutocompleteController.dispose();
    _plantAutocompleteController.dispose();
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
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(state, notifier)),
              if (state.groupedRules.isEmpty && !state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: AppTableEmptyState(
                      icon: Icons.gavel_rounded,
                      title: 'No rules found',
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverToBoxAdapter(child: _buildTableHeader()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == state.groupedRules.length) {
                        return state.hasMore
                            ? const AppTableLoadingMore()
                            : const SizedBox(height: 48);
                      }
                      return _buildGroupSection(
                        state.groupedRules[index],
                        state,
                        notifier,
                      );
                    }, childCount: state.groupedRules.length + 1),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
          if (state.isProcessing) const AppLoader(message: 'Processing...'),
        ],
      ),
    );
  }

  Widget _buildHeader(RuleState state, RuleNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddModal(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'CREATE RULE',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterRow(notifier, state),
          const SizedBox(height: 16),
          _buildStatsRow(state),
        ],
      ),
    );
  }

  Widget _buildStatsRow(RuleState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildStatChip(
              'PLANTS',
              state.groupedRules.length.toString(),
              const Color(0xFF141E7A),
            ),
            const SizedBox(width: 12),
            _buildStatChip(
              'TOTAL RULES',
              state.totalEntries.toString(),
              const Color(0xFF0284C7),
            ),
          ],
        ),
        Text(
          'Grouped by Plant',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(RuleNotifier notifier, RuleState state) {
    return Row(
      children: [
        // Plant Autocomplete
        Expanded(
          flex: 4,
          child: AppAutocomplete<PlantAutocompleteInfo>(
            controller: _plantAutocompleteController,
            hint: 'Select Plant...',
            optionsBuilder: (value) =>
                ref.read(plantNotifierProvider.notifier).searchPlants(value.text),
            displayStringForOption: (option) => option.plantName,
            onSelected: (option) {
              _plantAutocompleteController.text = option.plantName;
              notifier.setPlantId(option.plantId);
            },
          ),
        ),
        const SizedBox(width: 16),

        // Rule Search Autocomplete
        Expanded(
          flex: 4,
          child: AppAutocomplete<RuleAutocompleteInfo>(
            controller: _ruleAutocompleteController,
            hint: 'Search Rules...',
            optionsBuilder: (value) => notifier.searchRules(value.text),
            displayStringForOption: (option) => option.name,
            onSelected: (option) {
              _ruleAutocompleteController.text = option.name;
              notifier.setSearchName(option.name);
              notifier.loadRules(isReload: true);
            },
          ),
        ),
        const SizedBox(width: 16),

        // Status Dropdown
        Expanded(
          flex: 3,
          child: AppDropdown<int?>(
            value: state.selectedStatus,
            items: const [null, 1, 0],
            hint: 'Status: All',
            itemLabel: (val) {
              if (val == null) return 'Status: All';
              return val == 1 ? 'Status: Active' : 'Status: Inactive';
            },
            onChanged: (val) => notifier.setSelectedStatus(val),
          ),
        ),
        const SizedBox(width: 16),

        AppClearButton(
          onPressed: () {
            _ruleAutocompleteController.clear();
            _plantAutocompleteController.clear();
            notifier.clearFilters();
          },
        ),
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
      child: Row(
        children: [
          AppTableHeaderCell('Rule Details', flex: 6),
          const SizedBox(width: 16),
          AppTableHeaderCell('Parameter/Condition', flex: 4),
          const SizedBox(width: 16),
          AppTableHeaderCell('Template', flex: 4),
          const SizedBox(width: 16),
          AppTableHeaderCell('Status', width: 80),
          const SizedBox(width: 16),
          AppTableHeaderCell('Actions', width: 100),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
    RuleGroup group,
    RuleState state,
    RuleNotifier notifier,
  ) {
    return Column(
      children: [
        // Plant Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            border: Border(
              left: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              right: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              bottom: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          group.plantName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: const Color(0xFF141E7A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141E7A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${group.rules.length} RULES',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (group.plantFullAddress.isNotEmpty)
                      Text(
                        group.plantFullAddress,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Rule Rows
        ...group.rules.map(
          (rule) => _buildRuleRow(rule, group.rules.indexOf(rule), notifier),
        ),
      ],
    );
  }

  Widget _buildRuleRow(Rule rule, int index, RuleNotifier notifier) {
    final conditionText =
        rule.conditionType == 'BETWEEN'
            ? '${rule.threshold1} to ${rule.threshold2}'
            : '${rule.conditionType} ${rule.threshold1}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Rule Details
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rule.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (rule.tankNumber != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Text(
                          'TANK: ${rule.tankNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rule.companyName ?? '—',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Parameter / Condition
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.parameterType ?? '—',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141E7A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  conditionText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                if (rule.statusLabel != null)
                  Text(
                    rule.statusLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF0284C7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Template
          Expanded(
            flex: 4,
            child: Text(
              rule.templateName ?? '—',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          // Status
          SizedBox(
            width: 80,
            child: Center(child: AppStatusBadge(status: rule.isActive)),
          ),
          const SizedBox(width: 16),
          // Actions
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppTableActionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                  onTap: () => _showAddModal(rule),
                ),
                const SizedBox(width: 8),
                AppTableActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                  onTap: () => _confirmDelete(rule),
                ),
              ],
            ),
          ),
        ],
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
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(ruleProvider.notifier)
                  .deleteRule(rule.id);
              if (success && mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Rule deleted')));
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
