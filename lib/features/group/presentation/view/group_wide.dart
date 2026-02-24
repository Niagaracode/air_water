import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controller/group_provider.dart';
import '../model/group_model.dart';
import '../widgets/add_group_modal.dart';

class GroupWide extends ConsumerStatefulWidget {
  const GroupWide({super.key});

  @override
  ConsumerState<GroupWide> createState() => _GroupWideState();
}

class _GroupWideState extends ConsumerState<GroupWide> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // No pagination on backend for groups
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddModal([Group? group]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: group == null ? 'Add Group' : 'Edit Group',
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddGroupModal(group: group);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupProvider);
    final notifier = ref.read(groupProvider.notifier);

    if (state.searchQuery != _searchController.text &&
        state.searchQuery.isEmpty) {
      _searchController.text = '';
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildHeader(state, notifier),
            ),
          ),
          if (state.isLoading && state.plantUserCounts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF141E7A)),
                ),
              ),
            )
          else if (state.error != null)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            )
          else
            _buildVirtualizedTable(state, notifier),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildHeader(GroupState state, GroupNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
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
                    'GROUP MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage access groups by assigning specific plants and tanks to control user permissions.',
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
                label: const Text('ADD GROUP'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'FILTER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  hint: 'Search By Plant Name',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  onSubmitted: (v) {
                    notifier.setSearchQuery(v);
                    notifier.loadPlantUserCounts();
                  },
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  notifier.clearFilters();
                },
                child: Text(
                  'CLEAR',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.plantUserCounts.length} of ${state.totalEntries} entries',
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

  Widget _buildVirtualizedTable(GroupState state, GroupNotifier notifier) {
    if (state.plantUserCounts.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppTableEmptyState(
          icon: Icons.group_work_outlined,
          title: 'No groups found',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverMainAxisGroup(
        slivers: [
          // Table header — navy
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(color: Color(0xFF141E7A)),
              child: Row(
                children: [
                  const AppTableHeaderCell('SI.NO', width: 60),
                  const AppTableHeaderCell('Plant Name / Location', flex: 3),
                  const AppTableHeaderCell('Assigned Groups', flex: 3),
                  const AppTableHeaderCell('Tanks', width: 80),
                  const AppTableHeaderCell('Total Users', width: 100),
                  const AppTableHeaderCell('Action', width: 80),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: state.plantUserCounts.length,
            itemBuilder: (context, index) {
              final plant = state.plantUserCounts[index];
              return _buildPlantRow(plant, index, notifier);
            },
          ),
          // Bottom cap
          const SliverToBoxAdapter(child: AppTableBottomCap()),
        ],
      ),
    );
  }

  Widget _buildPlantRow(
    PlantUserCount plant,
    int index,
    GroupNotifier notifier,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFE5E7EB)),
          right: BorderSide(color: Color(0xFFE5E7EB)),
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppTableCell((index + 1).toString().padLeft(2, '0'), width: 60),
          AppTableCell(
            null,
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.plantName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (plant.location != null)
                  Text(
                    plant.location!,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          AppTableCell(
            null,
            flex: 3,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: plant.groupNames.map<Widget>((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          AppTableCell(
            plant.tankCount.toString(),
            width: 80,
            textAlign: TextAlign.center,
          ),
          AppTableCell(
            plant.userCount.toString(),
            width: 100,
            textAlign: TextAlign.center,
            bold: true,
            color: const Color(0xFF141E7A),
            fontSize: 14,
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: AppTableActionButton(
                icon: Icons.visibility_outlined,
                color: const Color(0xFF16A34A),
                bg: const Color(0xFFDCFCE7),
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
