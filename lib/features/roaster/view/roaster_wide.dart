import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/view/roster_edit_view.dart';
import 'package:air_water/features/roaster/presentation/widgets/add_roaster_modal.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_clear_button.dart';

class RoasterWide extends ConsumerStatefulWidget {
  const RoasterWide({super.key});

  @override
  ConsumerState<RoasterWide> createState() => _RoasterWideState();
}

class _RoasterWideState extends ConsumerState<RoasterWide> {
  final TextEditingController _filterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(roasterNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToEdit(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RosterEditView(rosterId: id)),
    ).then((_) {
      if (!mounted) return;
      ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true);
    });
  }

  void _showRosterEditor(Roster roster) async {
    final notifier = ref.read(roasterNotifierProvider.notifier);
    
    // Show a minimal loading state if needed, but for now just fetch
    final members = await notifier.getRosterMembers(roster.id);
    final templateMembers = members.where((m) => m.userId == null).toList();

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EditRoster',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AddRosterModal(roster: roster, templateMembers: templateMembers),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    ).then((result) {
      if (result == true) {
        ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true);
      }
    });
  }

  void _showAddRoster() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddRoster',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const AddRosterModal(),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    ).then((result) {
      if (result == true) {
        ref.read(roasterNotifierProvider.notifier).loadRosters(isReload: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roasterNotifierProvider);
    final notifier = ref.read(roasterNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildHeader(state, notifier),
          ),
          if (!state.isLoading || state.rosters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildFixedTableHeader(),
            ),
          Expanded(
            child: state.isLoading && state.rosters.isEmpty
                ? const AppTableInitialLoader()
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : _buildVirtualizedTable(state, notifier),
          ),
          if (state.isLoading && state.rosters.isNotEmpty)
            const AppTableLoadingMore(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(RoasterState state, RoasterNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROASTER MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Centralize notification teams, members, and status management.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddRoster,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'ADD ROSTER',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'FILTER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterRow(state, notifier),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.rosters.length} of ${state.totalEntries} entries',
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

  Widget _buildFilterRow(RoasterState state, RoasterNotifier notifier) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: _filterController,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: 'Search By Name',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6B7280)),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF141E7A), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (v) {
              notifier.setSearchName(v);
              notifier.loadRosters(isReload: true);
            },
          ),
        ),
        const SizedBox(width: 16),
        AppClearButton(
          onPressed: () {
            _filterController.clear();
            notifier.setSearchName('');
            notifier.loadRosters(isReload: true);
          },
        ),
      ],
    );
  }

  Widget _buildFixedTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        border: Border(
          top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        ),
      ),
      child: const Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 60),
          AppTableHeaderCell('Description', flex: 4),
          AppTableHeaderCell('Role', flex: 2),
          AppTableHeaderCell('Parameter', flex: 2),
          AppTableHeaderCell('Template', flex: 2),
          AppTableHeaderCell('Contacts', flex: 1),
          AppTableHeaderCell('Status', flex: 1),
          AppTableHeaderCell('Action', width: 100),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(RoasterState state, RoasterNotifier notifier) {
    if (state.rosters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: AppTableEmptyState(
          icon: Icons.assignment_outlined,
          title: 'No rosters found',
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: state.rosters.length,
            itemBuilder: (context, index) {
              final roster = state.rosters[index];
              return _buildRosterRow(roster, index, notifier);
            },
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(child: AppTableBottomCap()),
        ),
      ],
    );
  }

  Widget _buildRosterRow(Roster roster, int index, RoasterNotifier notifier) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppTableCell((index + 1).toString().padLeft(2, '0'), width: 60),
          _buildClickableCell(roster.description, flex: 4, color: const Color(0xFF2563EB), onTap: () => _navigateToEdit(roster.id)),
          _buildClickableCell(roster.roleNames ?? '-', flex: 2, color: const Color(0xFF1F2937), onTap: () => _showRosterEditor(roster)),
          _buildClickableCell(roster.parameterNames ?? '-', flex: 2, color: const Color(0xFF1F2937), onTap: () => _showRosterEditor(roster)),
          _buildClickableCell(roster.messageTemplateNames ?? '-', flex: 2, color: const Color(0xFF1F2937), onTap: () => _showRosterEditor(roster)),
          AppTableCell(roster.activeContacts.toString().padLeft(2, '0'), flex: 1),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(status: roster.enabled),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              children: [
                AppTableActionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2563EB),
                  bg: const Color(0xFFEFF6FF),
                  onTap: () => _showRosterEditor(roster),
                ),
                const SizedBox(width: 8),
                AppTableActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                  onTap: () => _confirmDelete(roster, notifier),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableCell(String text, {required int flex, bool bold = false, Color color = const Color(0xFF2563EB), required VoidCallback onTap}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Roster roster, RoasterNotifier notifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Roster'),
        content: const Text('Are you sure you want to delete this roster?'),
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
    if (confirm == true) {
      await notifier.deleteRoaster(roster.id);
    }
  }
}