import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import '../presentation/widgets/add_roster_group_modal.dart';
import '../../asset_group/domain/models/asset_group_model.dart';
import '../../asset_group/presentation/controller/asset_group_provider.dart';
import '../presentation/widgets/edit_roster_group_modal.dart';

class RoasterNarrow extends ConsumerWidget {
  const RoasterNarrow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roasterNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Dismiss',
            barrierColor: Colors.black.withValues(alpha: 0.5),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) => const AddRosterGroupModal(),
            transitionBuilder: (context, anim1, anim2, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(anim1),
                child: child,
              );
            },
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create roster',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildHeader(context, ref),
            ),
            Expanded(
              child: state.isLoading && state.rosters.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: state.rosters.length,
                      itemBuilder: (context, index) {
                        final roster = state.rosters[index];
                        return _buildRosterCard(context, ref, roster);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'ROSTER MANAGEMENT',
            style: TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: primary, size: 20),
          onPressed: () => ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildRosterCard(BuildContext context, WidgetRef ref, Roster roster) {
    final displayTitle = _cleanDescription(roster.description);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final groupState = ref.read(rosterGroupProvider);
          final group = groupState.groups.firstWhere(
            (g) => g.id == roster.rosterGroupId,
            orElse: () => AssetGroupModel(
              id: roster.rosterGroupId ?? 0,
              name: _cleanDescription(roster.description),
              description: '',
              displayInTree: true,
              status: roster.enabled,
              domain: 'ROSTER',
              companyId: roster.companyId,
              criteria: const [],
            ),
          );

          await showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Dismiss',
            barrierColor: Colors.black.withValues(alpha: 0.5),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) =>
                EditRosterGroupModal(group: group),
            transitionBuilder: (context, anim1, anim2, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(anim1),
                child: child,
              );
            },
          );
          ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(roster.enabled == 1),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                    onPressed: () => _deleteRoster(context, ref, roster),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                     Expanded(child: _buildInfoItem(Icons.people_outline, 'Active Contacts', roster.activeContacts.toString())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRoster(BuildContext context, WidgetRef ref, Roster roster) async {
    final cleanDesc = _cleanDescription(roster.description);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Roster', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "$cleanDesc"?', style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(roasterNotifierProvider.notifier).deleteRoaster(roster.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roster deleted successfully')),
        );
      }
    }
  }

  String _cleanDescription(String desc) {
    final enDashIndex = desc.indexOf(' – ');
    if (enDashIndex != -1) {
      return desc.substring(0, enDashIndex).trim();
    }
    final hyphenIndex = desc.indexOf(' - ');
    if (hyphenIndex != -1) {
      return desc.substring(0, hyphenIndex).trim();
    }
    return desc;
  }

  Widget _buildStatusChip(bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: enabled ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5), width: 0.5),
      ),
      child: Text(
        enabled ? 'Enabled' : 'Disabled',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: enabled ? const Color(0xFF166534) : const Color(0xFF991B1B),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ],
    );
  }
}