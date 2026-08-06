import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../core/helpers/app_colors_helper.dart';
import '../controller/user_provider.dart';
import '../model/user_model.dart';
import '../widgets/add_user_modal.dart';
import '../../../../shared/widgets/app_clear_button.dart';

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
    final currentUser = ref.read(userProvider).currentUser;
    if (user != null && currentUser?.roleId == 2 && user.roleId == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin role users cannot edit SuperAdmin accounts'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: AddUserModal(user: user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final notifier = ref.read(userProvider.notifier);

    // Sync search controller with state
    if (state.searchQuery != _searchController.text &&
        state.searchQuery.isEmpty) {
      _searchController.text = '';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        elevation: 2,
        onPressed: () => _showAddModal(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add user',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state),
                  const SizedBox(height: 16),
                  _buildSearchRow(notifier),
                ],
              ),
            ),
          ),
          if (state.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildErrorBanner(state.error!),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            sliver: _buildVirtualizedList(state, notifier),
          ),
          if (state.isLoading && state.users.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Loading more users…',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  Widget _buildHeader(UserState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.people_alt_rounded, color: primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'USER MANAGEMENT',
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
                '${state.users.length} user${state.users.length == 1 ? '' : 's'} found',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow(UserNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E9F0)),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 20, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                notifier.setSearchQuery(value);
                notifier.loadUsers();
              },
            ),
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

  Widget _buildVirtualizedList(UserState state, UserNotifier notifier) {
    if (state.isLoading && state.users.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!state.isLoading && state.users.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.person_search_rounded,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No users found',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    final initials = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()[0].toUpperCase()
        : '?';

    final roleColor = AppColorsHelper.colorForRole(user.roleName);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAddModal(user),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with gradient/ring
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: roleColor.withValues(alpha: 0.12),
                        child: Text(
                          initials,
                          style: GoogleFonts.outfit(
                            color: roleColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      // Optional: subtle ring
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: roleColor.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.email ?? '—',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Role badge (pill)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            user.roleName ?? '—',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: roleColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button + chevron in a row
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              title: const Text('Delete User'),
                              content: Text(
                                'Are you sure you want to delete ${user.fullName}? This action cannot be undone.',
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
                            final success = await notifier.deleteUser(user.userId);
                            if (mounted) {
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('User deleted successfully'),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ref.read(userProvider).error ??
                                          'Failed to delete user',
                                    ),
                                    backgroundColor: const Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        },
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
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.red.shade700, size: 18),
            onPressed: () => ref.read(userProvider.notifier).loadUsers(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}