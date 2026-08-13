import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/rule_group/view/rule_group_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/view_header.dart';
import '../model/rule_group_model.dart';
import '../provider/rule_group_provider.dart';

class RuleGroupWide extends ConsumerStatefulWidget {
  const RuleGroupWide({super.key});

  @override
  ConsumerState<RuleGroupWide> createState() => _RuleGroupWideState();
}

class _RuleGroupWideState extends ConsumerState<RuleGroupWide> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 40, right: 16, bottom: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Consumer(
                      builder: (context, ref, child) {

                        final state = ref.watch(ruleGroupProvider);

                        if (state.isLoading && state.ruleGroups.isEmpty) {
                          return SizedBox(
                            height: constraints.maxHeight - 48,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (state.error != null) {
                          return SizedBox(
                            height: constraints.maxHeight - 48,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(state.error!),
                                ],
                              ),
                            ),
                          );
                        }

                        if (state.ruleGroups.isEmpty) {
                          return SizedBox(
                            height: constraints.maxHeight - 48,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rule_folder, size: 64),
                                  const SizedBox(height: 16),
                                  Text('No Rule Groups Found'),
                                ],
                              ),
                            ),
                          );
                        }

                        // Numbered-circle + connecting-line timeline,
                        // matching the site/device management pages.
                        // No forced min-height here — content sizes naturally,
                        // so a single short card never triggers a scrollbar.
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.ruleGroups.length,
                          itemBuilder: (context, index) {
                            final rule = state.ruleGroups[index];
                            final isLast = index == state.ruleGroups.length - 1;
                            return _buildTimelineItem(
                              rule,
                              index + 1,
                              isLast,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Timeline column (numbered circle + connecting line) beside each
  // rule group card. Circle and line are left-aligned within their column
  // so the line clearly runs down the left side of the number, and the
  // line connects this circle down to the next one, stopping after the
  // last card.
  Widget _buildTimelineItem(RuleGroupModel rule, int index, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    // Centers the 2px line under the 28px circle above it.
                    padding: const EdgeInsets.only(left: 13),
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: primary.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildRuleGroupCard(rule),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    rule.ruleGroupName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
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
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level Events Section - Compact
                _buildLevelSection(levelRule),
                const SizedBox(height: 16),

                // Other Events Section
                if (otherRules.isNotEmpty) ...[
                  _buildOtherEventsSection(otherRules),
                  const SizedBox(height: 16),
                ],

                // Missing Data Section - Compact
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left:8, top: 20, right: 12),
          child: Text(
            'Level Events',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: levelRule.events.map((event) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black26,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      _getLevelIcon(event.description),
                      size: 20,
                      color: getColorForEvent(event.description),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      event.description,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: getColorForEvent(event.description).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
                      ),
                      child: Text(
                        '${event.value} ${event.comparator} ${event.unit}',
                        style: TextStyle(
                          fontSize: 13,
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
        ),
      ],
    );
  }

  Widget _buildOtherEventsSection(List<RuleModel> otherRules) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: otherRules.asMap().entries.map((entry) {
        final index = entry.key;
        final rule = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == otherRules.length - 1 ? 0 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: rule.events.map((event) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getCategoryColor(rule.category).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              event.description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              '${event.value} ${event.comparator} ${event.unit}',
                              style: TextStyle(
                                fontSize: 12,
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMissingDataSection(MissingDataModel missingData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF08A)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: const Color(0xFFCA8A04)),
          const SizedBox(width: 10),
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
          const Text(
            ' - Alert when no data received',
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
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'RULE GROUP MANAGEMENT',
      subtitle: 'Monitor your device thresholds and notification settings.',
      buttonText: 'Add rule',
      onPressed: () => _showAddModal(),
    );
  }

  void _showAddModal([RuleGroupModel? model]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddMessageTemplate',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => RuleGroupForm(initialRule: model, isNarrow: false,),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          ),
          child: child,
        );
      },
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