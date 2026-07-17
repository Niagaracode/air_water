import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/rule_group/view/rule_group_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/view_header.dart';
import '../model/rule_group_model.dart';
import '../provider/rule_group_provider.dart';

class RuleGroupNarrow extends ConsumerStatefulWidget {
  const RuleGroupNarrow({super.key});

  @override
  ConsumerState<RuleGroupNarrow> createState() => _RuleGroupNarrowState();
}

class _RuleGroupNarrowState extends ConsumerState<RuleGroupNarrow> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ruleGroupProvider);

    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () => _showAddModal(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Rule', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(ruleGroupProvider);

                if (state.isLoading && state.ruleGroups.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state.ruleGroups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rule_folder,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Rule Groups Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to create one',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  itemCount: state.ruleGroups.length,
                  itemBuilder: (context, index) {
                    final rule = state.ruleGroups[index];
                    return _buildRuleGroupCard(rule);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RULE GROUP MANAGEMENT',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monitor your device thresholds and notification settings.',
            style: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRuleGroupCard(RuleGroupModel rule) {
    final levelRule = rule.rules.firstWhere(
          (r) => r.category.toLowerCase() == 'level',
      orElse: () => rule.rules.first,
    );

    final otherRules = rule.rules
        .where((r) => r.category.toLowerCase() != 'level')
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rule.ruleGroupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      onPressed: () => _showAddModal(rule),
                      color: primary,
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      onPressed: () => _confirmDelete(rule),
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level Events Section
                _buildLevelSection(levelRule),
                const SizedBox(height: 12),

                // Other Events Section
                if (otherRules.isNotEmpty) ...[
                  _buildOtherEventsSection(otherRules),
                  const SizedBox(height: 12),
                ],

                // Missing Data Section
                if (levelRule.missingData != null)
                  _buildMissingDataSection(levelRule.missingData!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSection(RuleModel levelRule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level Events',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levelRule.events.map((event) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black26,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    _getLevelIcon(event.description),
                    size: 16,
                    color: getColorForEvent(event.description),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getColorForEvent(event.description).withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      '${event.value} ${event.comparator} ${event.unit}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: getColorForEvent(event.description),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOtherEventsSection(List<RuleModel> otherRules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Other Events',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        ...otherRules.map((rule) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(rule.category),
                        size: 14,
                        color: _getCategoryColor(rule.category),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rule.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: rule.events.map((event) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getCategoryColor(rule.category).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                event.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            Text(
                              '${event.value} ${event.comparator} ${event.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMissingDataSection(MissingDataModel missingData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFEF08A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: const Color(0xFFCA8A04)),
              const SizedBox(width: 8),
              const Text(
                'Missing Data:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF854D0E),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${missingData.hours}h ${missingData.minutes}m',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFCA8A04),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Alert when no data received',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF854D0E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _showAddModal([RuleGroupModel? model]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: RuleGroupForm(initialRule: model),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(RuleGroupModel rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Rule Group'),
        content: Text(
          'Are you sure you want to delete "${rule.ruleGroupName}"?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(ruleGroupProvider.notifier)
          .deleteRuleGroup(rule.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Rule group deleted successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Color getColorForEvent(String description) {
    switch (description.toLowerCase()) {
      case 'full':
        return const Color(0xFF3B82F6);
      case 'reorder':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFEF4444);
      case 'empty':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getLevelIcon(String category) {
    switch (category.toLowerCase()) {
      case 'full':
        return Icons.water_drop_outlined;
      case 'reorder':
        return Icons.swap_horiz;
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'empty':
        return Icons.inbox;
      default:
        return Icons.inbox;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pressure':
        return Icons.speed;
      case 'battery':
        return Icons.battery_std;
      case 'solar':
        return Icons.solar_power;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'pressure':
        return const Color(0xFF8B5CF6);
      case 'battery':
        return const Color(0xFF10B981);
      case 'solar':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }
}