import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../../../../../shared/widgets/app_clear_button.dart';
import '../controller/user_provider.dart';
import '../model/user_model.dart';
import '../widgets/add_user_modal.dart';

class UserWide extends ConsumerStatefulWidget {
  const UserWide({super.key});

  @override
  ConsumerState<UserWide> createState() => _UserWideState();
}

class _UserWideState extends ConsumerState<UserWide> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _companySearchController =
      TextEditingController();
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
    _companySearchController.dispose();
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
          if (state.isLoading && state.users.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF141E7A)),
                ),
              ),
            )
          else if (state.error != null)
            SliverToBoxAdapter(child: Center(child: Text(state.error!)))
          else
            _buildVirtualizedTable(state, notifier),
          if (state.isLoading && state.users.isNotEmpty)
            const SliverToBoxAdapter(child: AppTableLoadingMore()),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildHeader(UserState state, UserNotifier notifier) {
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
                    'USER MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Centralize user information including identification, roles, access, and status management.',
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
                label: Text(
                  'ADD USER',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
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
          _buildFilterRow(state, notifier),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.users.length} of ${state.totalEntries} entries',
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

  Widget _buildFilterRow(UserState state, UserNotifier notifier) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildUserNameAutocomplete(notifier)),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildCompanyField(state, notifier)),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: DropdownButton<int>(
              value: state.status,
              hint: Text(
                'Status',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              underline: const SizedBox(),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Active', style: GoogleFonts.inter(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 0,
                  child: Text(
                    'Inactive',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
              onChanged: (value) {
                notifier.setStatus(value);
                notifier.loadUsers();
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        AppClearButton(
          onPressed: () {
            _searchController.clear();
            _companySearchController.clear();
            notifier.clearFilters();
          },
        ),
      ],
    );
  }

  Widget _buildVirtualizedTable(UserState state, UserNotifier notifier) {
    if (state.users.isEmpty) {
      return const SliverToBoxAdapter(
        child: AppTableEmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No users found',
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
              decoration: const BoxDecoration(
                color: Color(0xFF141E7A),
                border: Border(
                  top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                  left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                  right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  AppTableHeaderCell('SI.NO', width: 70),
                  AppTableHeaderCell('User Name', flex: 2),
                  AppTableHeaderCell('Company', flex: 2),
                  AppTableHeaderCell('Phone Number', flex: 2),
                  AppTableHeaderCell('Email', flex: 2),
                  AppTableHeaderCell('Role', flex: 2),
                  AppTableHeaderCell('Status', flex: 1),
                  AppTableHeaderCell('Action', width: 100),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final user = state.users[index];
              return _buildUserRow(user, index, notifier);
            },
          ),
          // Bottom cap
          SliverToBoxAdapter(
            child: Container(
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  left: BorderSide(color: Color(0xFFE5E7EB)),
                  right: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(User user, int index, UserNotifier notifier) {
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
          AppTableCell((index + 1).toString().padLeft(2, '0'), width: 70),
          AppTableCell(user.fullName, flex: 2, bold: true),
          AppTableCell(user.companyName ?? '—', flex: 2),
          AppTableCell(user.mobileNumber ?? '—', flex: 2),
          AppTableCell(user.email ?? '—', flex: 2),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppRoleBadge(roleName: user.roleName),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppStatusBadge(status: user.status),
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
                  onTap: () => _showAddModal(user),
                ),
                const SizedBox(width: 8),
                AppTableActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEF2F2),
                  onTap: () => _confirmDelete(user, notifier),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNameAutocomplete(UserNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _searchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await notifier.getUserNameSuggestions(textEditingValue.text);
          },
          onSelected: (option) {
            notifier.setSearchQuery(option);
            notifier.loadUsers();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Search By Name',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF141E7A),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (v) {
                notifier.setSearchQuery(v);
                notifier.loadUsers();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompanyField(UserState state, UserNotifier notifier) {
    return TextField(
      controller: _companySearchController,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: 'Search By Company',
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9CA3AF),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.business_outlined,
          size: 20,
          color: Color(0xFF6B7280),
        ),
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
        notifier.loadUsers();
      },
    );
  }

  Future<void> _confirmDelete(User user, UserNotifier notifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
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
      await notifier.deleteUser(user.userId);
    }
  }
}
