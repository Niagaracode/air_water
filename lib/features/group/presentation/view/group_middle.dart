import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controller/group_provider.dart';
import '../model/group_model.dart';
import '../widgets/add_group_modal.dart';
import 'group_detail.dart';

class GroupMiddle extends ConsumerStatefulWidget {
  const GroupMiddle({super.key});

  @override
  ConsumerState<GroupMiddle> createState() => _GroupMiddleState();
}

class _GroupMiddleState extends ConsumerState<GroupMiddle> {
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
      // Future-proofing for pagination
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
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildFilterRow(state, notifier),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            )
          else
            _buildVirtualizedList(state, notifier),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'GROUP MANAGEMENT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () => _showAddModal(),
          child: const Text('ADD'),
        ),
      ],
    );
  }

  Widget _buildFilterRow(GroupState state, GroupNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: _searchController,
            hint: 'Search Plant Name',
            prefixIcon: const Icon(Icons.search, size: 20),
            onSubmitted: (v) {
              notifier.setSearchQuery(v);
              notifier.loadPlantUserCounts();
            },
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            _searchController.clear();
            notifier.clearFilters();
          },
          child: const Text('CLEAR'),
        ),
      ],
    );
  }

  Widget _buildVirtualizedList(GroupState state, GroupNotifier notifier) {
    if (state.plantUserCounts.isEmpty && !state.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No plant assignments found',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: state.plantUserCounts.length,
        itemBuilder: (context, index) {
          final plant = state.plantUserCounts[index];
          return _buildPlantCard(plant, notifier);
        },
      ),
    );
  }

  Widget _buildPlantCard(PlantUserCount plant, GroupNotifier notifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.plantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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
                TextButton(
                  onPressed: () {
                    // Navigation to detail
                  },
                  child: const Text('VIEW'),
                ),
              ],
            ),
            const Divider(height: 16),
            const Text(
              'ASSIGNED GROUPS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
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
            const SizedBox(height: 12),
            Row(
              children: [
                _countBadge(Icons.layers_outlined, 'Tanks', plant.tankCount),
                const SizedBox(width: 16),
                _countBadge(
                  Icons.people_outline,
                  'Users',
                  plant.userCount,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(
    IconData icon,
    String label,
    int count, {
    bool isPrimary = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isPrimary ? primary : Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isPrimary ? primary : Colors.black87,
          ),
        ),
      ],
    );
  }
}
