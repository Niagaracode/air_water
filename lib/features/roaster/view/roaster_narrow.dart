import 'package:air_water/core/helpers/app_colors_helper.dart';
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

class RoasterNarrow extends ConsumerStatefulWidget {
  const RoasterNarrow({super.key});

  @override
  ConsumerState<RoasterNarrow> createState() => _RoasterNarrowState();
}

class _RoasterNarrowState extends ConsumerState<RoasterNarrow> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roasterNotifierProvider);

    final filteredRosters = state.rosters.where((r) {
      if (_searchController.text.isEmpty) return true;
      final term = _searchController.text.toLowerCase();
      final displayTitle = _cleanDescription(r.description).toLowerCase();
      return displayTitle.contains(term);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        elevation: 2,
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
                ).animate(
                  CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                ),
                child: child,
              );
            },
          );
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Create roster',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _buildHeader(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: state.isLoading && filteredRosters.isEmpty
                ? const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
                : filteredRosters.isEmpty
                ? SliverToBoxAdapter(
              child: _buildEmptyState(),
            )
                : SliverList.builder(
              itemCount: filteredRosters.length,
              itemBuilder: (context, index) {
                final roster = filteredRosters[index];
                return _buildRosterCard(roster);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.schedule_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 2),
                  Text(
                    'Manage your roster groups and schedules',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search bar with built-in clear button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: TextFormField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search rosters by name',
              hintStyle: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  return value.text.isNotEmpty
                      ? IconButton(
                    onPressed: _clearSearch,
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                      : const SizedBox.shrink();
                },
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRosterCard(Roster roster) {
    final displayTitle = _cleanDescription(roster.description);
    final groupColor = AppColorsHelper.colorForGroup(displayTitle);

    return InkWell(
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
              ).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOut),
              ),
              child: child,
            );
          },
        );
        ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Roster icon with color
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: groupColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: roster.enabled == 1
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: roster.enabled == 1
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            roster.enabled == 1 ? 'Enabled' : 'Disabled',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: roster.enabled == 1
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  InkWell(
                    onTap: () => _deleteRoster(roster),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stats container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: groupColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: groupColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people_outline_rounded,
                        size: 16,
                        color: groupColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Contacts',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          roster.activeContacts.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: groupColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Roster',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: groupColor,
                        ),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No rosters found',
              style: GoogleFonts.inter(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create your first roster to get started',
              style: GoogleFonts.inter(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRoster(Roster roster) async {
    final cleanDesc = _cleanDescription(roster.description);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Delete Roster',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$cleanDesc"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(roasterNotifierProvider.notifier).deleteRoaster(roster.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Roster deleted successfully'),
            backgroundColor: Colors.green.shade700,
          ),
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
}