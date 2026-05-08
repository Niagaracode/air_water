import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/table_data_cell.dart';
import '../../../../shared/widgets/table_header_cell.dart';
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
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: state.isLoading ? Center(
        child: CircularProgressIndicator(),
      ) : Column(
        children: [
          _buildHeader(state, notifier),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _buildDataTable(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserState state, UserNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      margin: const EdgeInsets.only(left: 26, right: 26, top: 26, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      color: Colors.black38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddModal(),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
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
          const SizedBox(height: 16),
          _buildFilterRow(state, notifier),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDataTable(UserState state, UserNotifier notifier) {

    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: (state.users.length * 45) + 50,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: DataTable2(
        dataRowColor: WidgetStateProperty.all(Colors.white),
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 800,
        headingRowHeight: 45,
        dataRowHeight: 45,
        dividerThickness: 0.4,
        headingRowColor: WidgetStateProperty.all(primary.withValues(alpha: 0.1)),
        columns: [
          DataColumn2(
            label: TableHeaderCell(label: 'SI.NO',),
            fixedWidth: 60,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'User Name'),
            size: ColumnSize.M,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Company'),
            size: ColumnSize.M,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Phone Number'),
            size: ColumnSize.S,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Email'),
            size: ColumnSize.M,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Role'),
            fixedWidth: 150.0,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Status'),
            fixedWidth: 100.0,
          ),
          const DataColumn2(
            label: TableHeaderCell(label: 'Action'),
            fixedWidth: 80.0,
          ),
        ],

        rows: List.generate(state.users.length, (index) {
          final user = state.users[index];
          return DataRow(
            cells: [
              DataCell(TableDataCell(label: '${index + 1}')),
              DataCell(TableDataCell(label: user.fullName, bold: true,)),
              DataCell(TableDataCell(label: user.companyName!)),
              DataCell(TableDataCell(label: user.mobileNumber!)),
              DataCell(TableDataCell(label: user.email!)),
              DataCell(Align(
                alignment: Alignment.centerLeft,
                child: AppRoleBadge(roleName: user.roleName),
              )),
              DataCell(AppStatusBadge(status: user.status)),
              DataCell(
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
              ),
            ],
          );
        }),
      ),
    );

  }

  Widget _buildFilterRow(UserState state, UserNotifier notifier) {
    return Row(
      children: [
        // Username search — dashboard style
        Expanded(flex: 2, child: _buildUserNameAutocomplete(notifier)),
        const SizedBox(width: 12),
        // Company search — dashboard style
        Expanded(flex: 2, child: _buildCompanyField(state, notifier)),
        const SizedBox(width: 12),
        // Status dropdown — dashboard style
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: state.status,
                isExpanded: true,
                hint: Text(
                  'All Status',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                icon: Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey.shade600),
                items: [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Active', style: GoogleFonts.outfit(fontSize: 14)),
                  ),
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Inactive', style: GoogleFonts.outfit(fontSize: 14)),
                  ),
                ],
                onChanged: (value) {
                  notifier.setStatus(value);
                  notifier.loadUsers();
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Filter/Clear icon — dashboard style
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141E7A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF141E7A)),
            tooltip: 'Clear all filters',
            onPressed: () {
              _searchController.clear();
              _companySearchController.clear();
              notifier.clearFilters();
            },
          ),
        ),
      ],
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
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (v) {
                  notifier.setSearchQuery(v);
                  if (v.isEmpty) notifier.loadUsers();
                },
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onSubmitted: (v) {
                  notifier.setSearchQuery(v);
                  notifier.loadUsers();
                },
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _companySearchController,
        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: 'Search By Company',
          hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
        onSubmitted: (v) {
          notifier.loadUsers();
        },
      ),
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