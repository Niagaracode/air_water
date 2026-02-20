import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/user_provider.dart';
import '../model/user_model.dart';
import '../widgets/add_user_modal.dart';

class UserNarrow extends ConsumerStatefulWidget {
  const UserNarrow({super.key});

  @override
  ConsumerState<UserNarrow> createState() => _UserNarrowState();
}

class _UserNarrowState extends ConsumerState<UserNarrow> {
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
      ref.read(userProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddModal([User? user]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add User',
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddUserModal(user: user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);

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
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildSearchRow(notifier),
                  if (state.error != null) _buildErrorBanner(state.error!),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: _buildVirtualizedList(state, notifier),
          ),
          if (state.isLoading && state.users.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          'USER MANAGEMENT',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () => _showAddModal(),
          child: const Text('ADD'),
        ),
      ],
    );
  }

  Widget _buildSearchRow(UserNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search By Name / Email',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              notifier.setSearchQuery(value);
              notifier.loadUsers();
            },
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            _searchController.clear();
            notifier.clearFilters();
          },
          child: const Text('CLEAR', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildVirtualizedList(UserState state, UserNotifier notifier) {
    if (state.isLoading && state.users.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!state.isLoading && state.users.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No Record Found',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];
        return _buildUserCard(user, notifier);
      },
    );
  }

  Widget _buildUserCard(User user, UserNotifier notifier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${user.roleName ?? '-'}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: _buildStatusChip(user.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.business_outlined, user.companyName ?? '-'),
                const SizedBox(height: 6),
                _infoRow(Icons.email_outlined, user.email ?? '-'),
                const SizedBox(height: 6),
                _infoRow(
                  Icons.phone_android_outlined,
                  user.mobileNumber ?? '-',
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showAddModal(user),
                      icon: Icon(Icons.edit_outlined, size: 20, color: primary),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete User'),
                            content: const Text(
                              'Are you sure you want to delete this user?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await notifier.deleteUser(user.userId);
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(int status) {
    final isActive = status == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 11),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 16),
            onPressed: () => ref.read(userProvider.notifier).loadUsers(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
