import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
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
      // Plant user counts currently don't use pagination on backend,
      // but we maintain the controller for consistency and future-proofing.
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

    // Sync search controller
    if (state.searchQuery != _searchController.text &&
        state.searchQuery.isEmpty) {
      _searchController.text = '';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterRow(state, notifier),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Showing ${state.plantUserCounts.length} of ${state.totalEntries} entries',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.isLoading && state.plantUserCounts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(child: CircularProgressIndicator()),
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
          if (state.isLoading && state.plantUserCounts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GROUP MANAGEMENT',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Manage Access Groups By Assigning Specific Plants And Tanks To Control User Permissions.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddModal(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('ADD GROUP'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(GroupState state, GroupNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
            child: const Text('CLEAR'),
          ),
          const SizedBox(width: 16),
          Text(
            '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(GroupState state, GroupNotifier notifier) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _tableHeaderCell('SI.NO', width: 60),
                  _tableHeaderCell('Plant Name / Location', flex: 3),
                  _tableHeaderCell('Assigned Groups', flex: 3),
                  _tableHeaderCell('Tanks', width: 80),
                  _tableHeaderCell('Total Users', width: 100),
                  _tableHeaderCell('Action', width: 80),
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
          SliverToBoxAdapter(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade200),
                  right: BorderSide(color: Colors.grey.shade200),
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.plantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (plant.location != null)
                    Text(
                      plant.location!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: plant.groupNames.map<Widget>((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          _tableCell(plant.tankCount.toString(), width: 80),
          _tableCell(
            plant.userCount.toString(),
            width: 100,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: primary,
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: IconButton(
                onPressed: () {
                  // Navigate to plant details if needed
                },
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String label, {int? flex, double? width}) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
  }

  Widget _tableCell(
    String value, {
    int? flex,
    double? width,
    TextStyle? style,
  }) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        value,
        style: style ?? const TextStyle(fontSize: 13),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
  }
}
