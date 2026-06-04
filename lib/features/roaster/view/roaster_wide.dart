import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../asset_group/domain/models/asset_group_model.dart';
import '../../asset_group/presentation/controller/asset_group_provider.dart';
import '../presentation/widgets/add_roster_group_modal.dart';
import '../presentation/widgets/edit_roster_group_modal.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../user/presentation/controller/user_provider.dart';

class RoasterWide extends ConsumerStatefulWidget {
  const RoasterWide({super.key});

  @override
  ConsumerState<RoasterWide> createState() => _RoasterWideState();
}

class _RoasterWideState extends ConsumerState<RoasterWide> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(rosterGroupProvider.notifier).loadGroups();
    });
  }

  void _editGroup(AssetGroupModel group) {
    showGeneralDialog(
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
  }

  Future<void> _confirmDeleteGroup(AssetGroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Roster Group'),
        content: Text('Are you sure you want to delete the group "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && group.id != null) {
      final success = await ref.read(assetGroupProvider.notifier).deleteGroup(group.id!);
      if (success) {
        ref.read(rosterGroupProvider.notifier).loadGroups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Roster group deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          final error = ref.read(assetGroupProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: ${error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(rosterGroupProvider);
    final userState = ref.watch(userProvider);
    final isSuperAdmin = userState.currentUser?.roleId == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          Expanded(
            child: groupState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupState.error != null
                ? Center(child: Text(groupState.error!))
                : _buildGroupTable(
                    groupState.groups
                        .where((g) => g.status == 1)
                        .toList(),
                    isSuperAdmin,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E7A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Color(0xFF141E7A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ROASTER MANAGEMENT',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select an asset group to configure notifications.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Dismiss',
                barrierColor: Colors.black.withValues(alpha: 0.5),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) =>
                    const AddRosterGroupModal(),
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
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              'CREATE GROUP',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141E7A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTable(List<AssetGroupModel> groups, bool isSuperAdmin) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No asset groups found',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF141E7A),
              ),
              child: Row(
                children: [
                  AppTableHeaderCell('SI.NO', width: 60),
                  if (isSuperAdmin) AppTableHeaderCell('COMPANY', flex: 2),
                  AppTableHeaderCell('GROUP NAME', flex: 2),
                  AppTableHeaderCell('DESCRIPTION', flex: 3),
                  AppTableHeaderCell('ACTION', width: 120),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) =>
                    _buildGroupRow(groups[i], i, isSuperAdmin),
              ),
            ),
            const AppTableBottomCap(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupRow(AssetGroupModel group, int index, bool isSuperAdmin) {
    return InkWell(
      onTap: () => _editGroup(group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            AppTableCell((index + 1).toString().padLeft(2, '0'), width: 60),
            if (isSuperAdmin)
              AppTableCell(
                group.companyName ?? '-',
                flex: 2,
                color: const Color(0xFF141E7A),
                bold: true,
              ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (group.criteria.any((c) => c.parameter == 'Site Name'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Site: ${group.criteria.firstWhere((c) => c.parameter == 'Site Name').value}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                group.description.isNotEmpty ? group.description : '-',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _confirmDeleteGroup(group),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Delete Group',
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141E7A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF141E7A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
