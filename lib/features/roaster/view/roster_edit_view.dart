import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/presentation/controller/roaster_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../user/presentation/model/user_model.dart';
import '../../user/presentation/controller/user_provider.dart';
import '../../../../core/app_theme/app_theme.dart';

class RosterEditView extends ConsumerStatefulWidget {
  final int rosterId;
  const RosterEditView({super.key, required this.rosterId});

  @override
  ConsumerState<RosterEditView> createState() => _RosterEditViewState();
}

class _RosterEditViewState extends ConsumerState<RosterEditView> {
  Roster? _roster;
  List<RosterMember> _members = [];
  bool _isLoading = true;
  List<Role> _roles = [];

  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  String _searchQuery = '';
  int? _selectedFilterRoleId;
  int? _selectedFilterStatus; // null: All, 1: Active, 0: Inactive

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _roster = await ref.read(roasterNotifierProvider.notifier).getRosterDetail(widget.rosterId);
    _members = await ref.read(roasterNotifierProvider.notifier).getRosterMembers(
      widget.rosterId,
      q: _searchQuery,
      roleId: _selectedFilterRoleId,
      status: _selectedFilterStatus,
    );
    _roles = await ref.read(userProvider.notifier).getRoles();
    setState(() => _isLoading = false);
  }

  void _showUserEditor([RosterMember? member]) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim2, anim3) => Align(
        alignment: Alignment.centerRight,
        child: _RosterUserEditor(roster: _roster!, member: member),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0)).animate(anim1),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_roster == null) return const Scaffold(body: Center(child: Text('Roster not found')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Roster',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF334155),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Delete Roster',
            onPressed: _deleteRoster,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 32),
        child: Column(
          children: [
            _buildSummaryHeader(),
            const SizedBox(height: 32),
            _buildFilterBar(),
            const SizedBox(height: 32),
            _buildMembersTable(_members),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(
            label: 'DESCRIPTION',
            child: Text(
              _cleanDescription(_roster!.description),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'STATUS',
                  child: Row(
                    children: [
                      _buildStatusBadge(_roster!.enabled == 1, 'Enabled', 'Disabled'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  label: 'ACTIVE CONTACTS',
                  icon: Icons.people_alt_rounded,
                  child: Text(
                    _roster!.activeContacts.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildSummaryCard(
            label: 'DESCRIPTION',
            child: Text(
              _cleanDescription(_roster!.description),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildSummaryCard(
            label: 'STATUS',
            child: Row(
              children: [
                _buildStatusBadge(_roster!.enabled == 1, 'Enabled', 'Disabled'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: 'DATA CHANNELS',
            icon: Icons.sensors_rounded,
            child: Text(
              _roster!.dataChannels.toString(),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: 'ACTIVE CONTACTS',
            icon: Icons.people_alt_rounded,
            child: Text(
              _roster!.activeContacts.toString(),
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required String label, required Widget child, IconData? icon}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      height: isMobile ? null : 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          if (isMobile) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMembersTable(List<RosterMember> members) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1300,
              child: Column(
                children: [
                  _buildTableHeader(),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) => _buildTableRow(members[index]),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildAddContactButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 35, child: _buildHeaderText('CONTACT PERSON')),
          Expanded(flex: 15, child: _buildHeaderText('COMPANY')),
          Expanded(flex: 15, child: _buildHeaderText('ROLE')),
          Expanded(flex: 12, child: _buildHeaderText('NOTIFICATION')),
          Expanded(flex: 12, child: _buildHeaderText('E2P')),
          Expanded(flex: 30, child: _buildHeaderText('ACTIONS')),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTableRow(RosterMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.displayName,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                ),
                Text(
                  member.username ?? '',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              member.companyName ?? '-',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              member.roleName ?? '-',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(member.emailNotif == 1, 'Email On', 'Email Off'),
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(member.emailToPhone == 1, 'E2P On', 'E2P Off'),
            ),
          ),
          Expanded(
            flex: 30,
            child: Row(
              children: [
                _buildActionIcon(Icons.edit_outlined, primary, primary.withValues(alpha: 0.1), () => _showUserEditor(member)),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.delete_outline_rounded, const Color(0xFFDC2626), const Color(0xFFFEF2F2), () => _confirmDelete(member)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, String activeText, String inactiveText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? activeText : inactiveText,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _confirmDelete(RosterMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Contact', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove ${member.displayName} from this roster?', style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && member.id != null) {
      final success = await ref.read(roasterNotifierProvider.notifier).removeMember(member.id!);
      if (success) {
        _loadData();
      }
    }
  }

  Future<void> _deleteRoster() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Roster', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this roster?', style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && _roster != null) {
      setState(() => _isLoading = true);
      final success = await ref.read(roasterNotifierProvider.notifier).deleteRoaster(_roster!.id);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Roster deleted successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete roster')),
          );
        }
      }
    }
  }

  Widget _buildAddContactButton() {
    return ElevatedButton.icon(
      onPressed: () => _showUserEditor(),
      icon: const Icon(Icons.person_add_rounded, size: 16),
      label: Text(
        'Add New Contact',
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFilterBar() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final searchField = LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _searchController,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await ref.read(userProvider.notifier).getUserNameSuggestions(textEditingValue.text);
          },
          onSelected: (option) {
            setState(() => _searchQuery = option);
            _loadData();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search Username...',
              prefixIcon: const Icon(Icons.search, size: 20),
              onChanged: (v) => setState(() => _searchQuery = v),
              onSubmitted: (v) {
                setState(() => _searchQuery = v);
                _loadData();
              },
              suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      setState(() => _searchQuery = '');
                      _loadData();
                    },
                  )
                : null,
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

    final roleDropdown = AppDropdown<Role>(
      items: _roles,
      value: _roles.where((r) => r.id == _selectedFilterRoleId).firstOrNull,
      hint: 'Filter by Role',
      itemLabel: (r) => r.name,
      onChanged: (v) {
        setState(() => _selectedFilterRoleId = v?.id);
        _loadData();
      },
    );

    final statusDropdown = AppDropdown<Map<String, dynamic>>(
      items: const [
        {'label': 'Active', 'value': 1},
        {'label': 'Inactive', 'value': 0},
      ],
      value: _selectedFilterStatus == null
        ? null
        : [{'label': 'Active', 'value': 1}, {'label': 'Inactive', 'value': 0}].firstWhere((s) => s['value'] == _selectedFilterStatus),
      hint: 'Filter by Status',
      itemLabel: (s) => s['label'] as String,
      onChanged: (v) {
        setState(() => _selectedFilterStatus = v?['value']);
        _loadData();
      },
    );

    final clearButton = IconButton(
      onPressed: () {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          _selectedFilterRoleId = null;
          _selectedFilterStatus = null;
        });
        _loadData();
      },
      icon: const Icon(Icons.filter_list_off_rounded),
      tooltip: 'Clear Filters',
      color: const Color(0xFF64748B),
    );

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            searchField,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: roleDropdown),
                const SizedBox(width: 12),
                Expanded(child: statusDropdown),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: clearButton,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: searchField,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: roleDropdown,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: statusDropdown,
          ),
          const SizedBox(width: 16),
          clearButton,
        ],
      ),
    );
  }


  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
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

class _RosterUserEditor extends ConsumerStatefulWidget {
  final Roster roster;
  final RosterMember? member;
  const _RosterUserEditor({required this.roster, this.member});

  @override
  ConsumerState<_RosterUserEditor> createState() => _RosterUserEditorState();
}

class _RosterUserEditorState extends ConsumerState<_RosterUserEditor> {
  Role? _selectedRole;
  User? _selectedUser;
  bool _emailEnabled = false;
  bool _emailToPhoneEnabled = false;
  bool _pushEnabled = false;
  bool _isLoading = false;

  List<Role> _roles = [];
  List<User> _allUsers = [];

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _emailEnabled = widget.member!.emailNotif == 1;
      _emailToPhoneEnabled = widget.member!.emailToPhone == 1;
      _pushEnabled = widget.member!.pushNotif == 1;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userNotifier = ref.read(userProvider.notifier);
      final roles = await userNotifier.getRoles();
      await userNotifier.loadUsers();
      final users = ref.read(userProvider).users;
      await ref.read(roasterNotifierProvider.notifier).getRosterMembers(widget.roster.id);

      if (mounted) {
        setState(() {
          final assignedRoleIds = widget.roster.roleIds;
          _roles = roles.where((r) => assignedRoleIds.contains(r.id)).toList();
          _allUsers = users;
          
          if (widget.member != null) {
            _selectedRole = _roles.where((r) => r.id == widget.member!.roleId).firstOrNull;
            _selectedUser = _allUsers.where((u) => u.userId == widget.member!.userId).firstOrNull;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedUser == null || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both a Role and a Username'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final data = {
      'roster_id': widget.roster.id,
      'user_id': _selectedUser!.userId,
      'role_id': _selectedRole?.id,
      'enabled': 1,
      'email_notif': _emailEnabled ? 1 : 0,
      'email_to_phone': _emailToPhoneEnabled ? 1 : 0,
      'push_notif': _pushEnabled ? 1 : 0,
    };
 
    bool success;
    if (widget.member != null) {
      success = await ref.read(roasterNotifierProvider.notifier).updateMember(widget.member!.id!, data);
    } else {
      success = await ref.read(roasterNotifierProvider.notifier).addMember(data);
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoBar(),
                            const SizedBox(height: 48),
                            _buildUserInformationSection(),
                            const SizedBox(height: 48),
                            _buildEmailSection(),
                            const SizedBox(height: 48),
                            _buildPushSection(),
                            const SizedBox(height: 64),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  widget.member != null ? 'SAVE CHANGES' : 'ADD CONTACT',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member != null ? 'Edit Contact' : 'Add New Contact',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure notification preferences for this roster member.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 22),
            color: const Color(0xFF6B7280),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.person_outline_rounded, 'USER INFORMATION'),
        const Divider(height: 32, thickness: 1, color: Color(0xFFF3F4F6)),
        Row(
          children: [
            Expanded(
              child: _buildLabelField(
                'ROLE',
                AppDropdown<Role>(
                  value: _selectedRole,
                  items: _roles,
                  hint: 'Select Role...',
                  itemLabel: (r) => r.name,
                  onChanged: (v) {
                    setState(() {
                      _selectedRole = v;
                      _selectedUser = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildLabelField(
                'USERNAME',
                AppDropdown<User>(
                  value: _selectedUser,
                  items: _selectedRole == null ? [] : _allUsers.where((u) => u.roleId == _selectedRole!.id).toList(),
                  hint: 'Select User...',
                  itemLabel: (u) => u.username,
                  onChanged: (v) => setState(() => _selectedUser = v),
                  enabled: _selectedRole != null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.email_outlined, 'EMAIL PREFERENCES'),
        const Divider(height: 32, thickness: 1, color: Color(0xFFF3F4F6)),
        _buildStatusSelector('EMAIL NOTIFICATIONS', 'Toggle automatic email alerts.', _emailEnabled, (v) => setState(() => _emailEnabled = v)),
        const SizedBox(height: 24),
        _buildStatusSelector('EMAIL TO PHONE', 'Forward email alerts to phone.', _emailToPhoneEnabled, (v) => setState(() => _emailToPhoneEnabled = v)),
      ],
    );
  }

  Widget _buildPushSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.notifications_active_outlined, 'PUSH NOTIFICATIONS'),
        const Divider(height: 32, thickness: 1, color: Color(0xFFF3F4F6)),
        _buildStatusSelector('MOBILE PUSH', 'Toggle real-time app notifications.', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        field,
      ],
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE1FF)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Members with enabled notifications will receive alerts based on their assigned role and message template.',
              style: GoogleFonts.inter(fontSize: 13, color: primary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12, color: primary, letterSpacing: 1.1),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: primary,
          ),
        ],
      ),
    );
  }
}
