import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controller/group_provider.dart';
import '../model/group_model.dart';
import '../widgets/add_group_modal.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import 'joint_site_detail_view.dart';

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
          if (state.isLoading && state.siteUserCounts.isEmpty)
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF141E7A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('ADD GROUP'),
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
            hint: 'Search Site Name',
            prefixIcon: const Icon(Icons.search, size: 20),
            onSubmitted: (v) {
              notifier.setSearchQuery(v);
              notifier.loadSiteUserCounts();
            },
          ),
        ),
        const SizedBox(width: 8),
        AppClearButton(
          onPressed: () {
            _searchController.clear();
            notifier.clearFilters();
          },
        ),
      ],
    );
  }

  Widget _buildVirtualizedList(GroupState state, GroupNotifier notifier) {
    if (state.siteUserCounts.isEmpty && !state.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No site assignments found',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: state.siteUserCounts.length,
        itemBuilder: (context, index) {
          final site = state.siteUserCounts[index];
          return _buildSiteCard(site, notifier);
        },
      ),
    );
  }

  Widget _buildSiteCard(SiteUserCount site, GroupNotifier notifier) {
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
                        site.siteName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (site.location != null)
                        Text(
                          site.location!,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JointSiteDetailView(
                          siteId: site.siteId,
                        ),
                      ),
                    );
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
              children: site.groupNames.map<Widget>((name) {
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
                _countBadge(Icons.layers_outlined, 'Tanks', site.tankCount),
                const SizedBox(width: 16),
                _countBadge(
                  Icons.people_outline,
                  'Users',
                  site.userCount,
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
