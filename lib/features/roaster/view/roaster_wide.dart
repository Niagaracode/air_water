import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../asset_group/domain/models/asset_group_model.dart';
import '../../asset_group/presentation/controller/asset_group_provider.dart';
import '../presentation/widgets/add_roster_group_modal.dart';
import '../presentation/widgets/edit_roster_group_modal.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../user/presentation/controller/user_provider.dart';

/// -------- Shared style constants (avoids re-allocating on every rebuild) --------
class _RosterColors {
  static const bg = Color(0xFFF8FAFC);
  static const iconTint = Color(0xFF141E7A);
  static const heading = Color(0xFF111827);
  static const subText = Color(0xFF6B7280);
  static const rowTitle = Color(0xFF1F2937);
  static const rowDivider = Color(0xFFF3F4F6);
  static const emptyIcon = Color(0xFF9CA3AF);
}

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

  void _openAddGroupModal() {
    _showSlideInDialog(const AddRosterGroupModal());
  }

  void _editGroup(AssetGroupModel group) {
    _showSlideInDialog(EditRosterGroupModal(group: group));
  }

  /// Shared slide-in-from-right dialog transition so Add/Edit stay consistent.
  void _showSlideInDialog(Widget page) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => page,
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
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
        content: Text(
          'Are you sure you want to delete the group "${group.name}"?',
        ),
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

    if (confirm != true || group.id == null) return;
    if (!mounted) return;

    final success = await ref
        .read(assetGroupProvider.notifier)
        .deleteGroup(group.id!);

    if (!mounted) return;

    if (success) {
      ref.read(rosterGroupProvider.notifier).loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roster group deleted successfully')),
      );
    } else {
      final error = ref.read(assetGroupProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete group: ${error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(rosterGroupProvider);
    final userState = ref.watch(userProvider);
    final isSuperAdmin = userState.currentUser?.roleId == 1;

    return Scaffold(
      backgroundColor: _RosterColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          Expanded(
            child: switch (groupState) {
              _ when groupState.isLoading =>
              const Center(child: CircularProgressIndicator()),
              _ when groupState.error != null =>
                  Center(child: Text(groupState.error!)),
              _ => _buildGroupTable(
                groupState.groups.where((g) => g.status == 1).toList(),
                isSuperAdmin,
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      margin: const EdgeInsets.only(left: 26, right: 26, top: 26, bottom: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ROSTER MANAGEMENT',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select an User group to configure notifications.',
                  style: GoogleFonts.inter(color: Colors.black38, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _openAddGroupModal,
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
              backgroundColor: primary,
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
              'No user groups found',
              style: GoogleFonts.inter(color: _RosterColors.emptyIcon),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              border: Border(
                left: BorderSide(color: Colors.grey.shade300, width: 1),
                right: BorderSide(color: Colors.grey.shade300, width: 1),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: const [
                AppTableHeaderCell('SI.NO', width: 60),
                AppTableHeaderCell('GROUP NAME', flex: 2),
                AppTableHeaderCell('CONTACTS COUNT', width: 130),
                AppTableHeaderCell('DESCRIPTION', flex: 3),
                AppTableHeaderCell('ACTION', width: 100),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (_, i) => _GroupRow(
                group: groups[i],
                index: i,
                isLast: i == groups.length - 1,
                isSuperAdmin: isSuperAdmin,
                onEdit: _editGroup,
                onDelete: _confirmDeleteGroup,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted into its own widget so each row only rebuilds itself
/// (e.g. on hover) instead of the whole list.
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.index,
    required this.isLast,
    required this.isSuperAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final AssetGroupModel group;
  final int index;
  final bool isLast;
  final bool isSuperAdmin;
  final ValueChanged<AssetGroupModel> onEdit;
  final ValueChanged<AssetGroupModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final siteCriterion = group.criteria
        .where((c) => c.parameter == 'Site Name')
        .cast<dynamic>()
        .firstOrNull;

    final borderRadius = isLast
        ? const BorderRadius.only(
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    )
        : BorderRadius.zero;

    return Material(
      color: Colors.white,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: () => onEdit(group),
        hoverColor: _RosterColors.iconTint.withValues(alpha: 0.03),
        splashColor: _RosterColors.iconTint.withValues(alpha: 0.08),
        borderRadius: borderRadius,
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.grey.shade300, width: 1),
              right: BorderSide(color: Colors.grey.shade300, width: 1),
              bottom: isLast
                  ? BorderSide(color: Colors.grey.shade300, width: 1)
                  : const BorderSide(color: _RosterColors.rowDivider),
            ),
            borderRadius: borderRadius,
          ),
          child: Row(
            children: [
              AppTableCell((index + 1).toString().padLeft(2, '0'), width: 60),
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
                        color: _RosterColors.rowTitle,
                      ),
                    ),
                    if (siteCriterion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Site: ${siteCriterion.value}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _RosterColors.subText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 130,
                child: Center(
                  child: Text(
                    (group.rosterCount ?? 0).toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _RosterColors.rowTitle,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  group.description.isNotEmpty ? group.description : '-',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _RosterColors.subText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      // IconButton consumes the tap itself, so this
                      // never triggers the row's onEdit as well.
                      onPressed: () => onDelete(group),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      tooltip: 'Delete Group',
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _RosterColors.iconTint.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: _RosterColors.iconTint,
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
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}