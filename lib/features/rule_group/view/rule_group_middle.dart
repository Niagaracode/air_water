import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../model/rule_group_model.dart';
import '../provider/rule_group_provider.dart';
import 'rule_group_form.dart';

class RuleGroupMiddle extends ConsumerStatefulWidget {
  const RuleGroupMiddle({super.key});

  @override
  ConsumerState<RuleGroupMiddle> createState() => _RuleGroupMiddleState();
}

class _RuleGroupMiddleState extends ConsumerState<RuleGroupMiddle> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ruleGroupProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildBody(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'RULE GROUPS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddModal(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('ADD RULE GROUP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RuleGroupState state) {
    if (state.isLoading && state.ruleGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (state.ruleGroups.isEmpty) {
      return const Center(
        child: Text(
          'No Rule Groups Found',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.ruleGroups.length,
      itemBuilder: (context, index) {
        final rule = state.ruleGroups[index];
        return _buildRuleGroupCard(rule);
      },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    rule.ruleGroupName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showAddModal(rule),
                      icon: Icon(Icons.edit_outlined, size: 18, color: primary),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _confirmDelete(rule),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level Section
                _buildLevelSection(levelRule),
                const SizedBox(height: 16),

                // Other Rules Section (Wrapped grid for Tablet width)
                if (otherRules.isNotEmpty) ...[
                  const Text(
                    'Threshold Events',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: otherRules.map((r) {
                      return SizedBox(
                        width: 320,
                        child: _buildOtherRuleCard(r),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
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
        const Text(
          'Level Events',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: levelRule.events.map((event) {
            final eventColor = getColorForEvent(event.description);
            return Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getLevelIcon(event.description),
                    size: 18,
                    color: eventColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      '${event.value} ${event.comparator} ${event.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: eventColor,
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

  Widget _buildOtherRuleCard(RuleModel rule) {
    final catColor = _getCategoryColor(rule.category);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(rule.category),
                  size: 16,
                  color: catColor,
                ),
                const SizedBox(width: 8),
                Text(
                  rule.category,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: catColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${event.value} ${event.comparator} ${event.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
  }

  Widget _buildMissingDataSection(MissingDataModel missingData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFEF08A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFCA8A04)),
          const SizedBox(width: 10),
          const Text(
            'Missing Data:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF854D0E),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${missingData.hours}h ${missingData.minutes}m',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCA8A04),
            ),
          ),
          const Expanded(
            child: Text(
              ' - Alert when no data received from device',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF854D0E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddModal([RuleGroupModel? model]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddRuleGroup',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => RuleGroupForm(initialRule: model),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(ruleGroupProvider.notifier).deleteRuleGroup(rule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rule group deleted successfully')),
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
