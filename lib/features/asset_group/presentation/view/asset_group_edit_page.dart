import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../product/provider/product_provider.dart';
import '../controller/asset_group_provider.dart';
import '../../domain/models/asset_group_model.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';
import '../../../site/presentation/controller/site_provider.dart';
import '../../../device/presentation/controller/device_provider.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/app_theme/app_theme.dart';

class AssetGroupEditPage extends ConsumerStatefulWidget {
  final AssetGroupModel? group;
  const AssetGroupEditPage({super.key, this.group});

  @override
  ConsumerState<AssetGroupEditPage> createState() => _AssetGroupEditPageState();
}

class _AssetGroupEditPageState extends ConsumerState<AssetGroupEditPage> {
  final _formKey = GlobalKey<FormState>();
  List<AssetCriteria> _criteria = [];
  List<AssetGroupUser> _assignedUsers = [];
  User? _selectedUserForAssignment;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _displayInTree = true;
  int _initialCriteriaCount = 0;
  bool _didAutoAssign = false;
  bool _isLoadingDetails = false;
  int? _selectedCompanyId;
  List<CompanyAutocomplete> _companies = [];
  bool _isLoadingCompanies = false;

  final List<String> _parameters = [
    'City',
    'Country',
    'DeviceID',
    'Product',
    'Site Name',
    'State or Province',
    'Tank Name',
  ];
  final List<String> _logics = ['Like', '=', '!='];
  final List<String> _operators = ['Or', 'And'];

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController = TextEditingController(text: widget.group!.name);
      _descriptionController = TextEditingController(
        text: widget.group!.description,
      );
      _displayInTree = widget.group!.displayInTree;

      Future.microtask(() => _loadFullDetails());
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _displayInTree = true;
      _addCriteria();
    }

    // Load all users to show in the access control table
    Future.microtask(() {
      ref.read(userProvider.notifier).loadUsers();
      _checkSuperAdminAndLoadCompanies();
    });
  }

  Future<void> _checkSuperAdminAndLoadCompanies() async {
    final user = ref.read(userProvider).currentUser;
    if (user != null) {
      if (user.roleId == 1) {
        setState(() => _isLoadingCompanies = true);
        final results = await ref
            .read(userProvider.notifier)
            .searchCompanies('');
        if (mounted) {
          setState(() {
            _companies = results;
            _isLoadingCompanies = false;
            if (widget.group == null) {
              _selectedCompanyId = 216;
            }
          });
        }
      } else {
        setState(() {
          _selectedCompanyId = user.companyId;
        });
      }
    }
  }

  Future<void> _loadFullDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      await ref
          .read(assetGroupProvider.notifier)
          .loadGroupById(widget.group!.id!);
      final fullGroup = ref.read(assetGroupProvider).currentGroup;

      if (fullGroup != null && mounted) {
        setState(() {
          _criteria = List.from(fullGroup.criteria);
          // Sanitize operators for legacy data
          for (var rule in _criteria) {
            if (!_operators.contains(rule.operator)) {
              rule.operator = _operators.first;
            }
            if (!_logics.contains(rule.logic)) {
              rule.logic = _logics.contains('=') ? '=' : _logics.first;
            }
          }
          _initialCriteriaCount = _criteria.length;
          _assignedUsers = List.from(
            (fullGroup.users ?? []).where((u) {
              final role = (u.roleName ?? '').toLowerCase().replaceAll(' ', '');
              return !role.contains('superadmin');
            }),
          );
          _selectedCompanyId = fullGroup.companyId;
          if (_criteria.isEmpty) _addCriteria();
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load group details: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addCriteria() {
    final selectedParameters = _criteria.map((c) => c.parameter).toSet();
    final nextParameter = _parameters.firstWhere(
      (p) => !selectedParameters.contains(p),
      orElse: () => _parameters.first,
    );
    setState(() {
      _criteria.add(
        AssetCriteria(
          parameter: nextParameter,
          logic: 'Like',
          value: '',
          operator: 'Or',
        ),
      );
    });
  }

  void _removeCriteria(int index) {
    setState(() {
      _criteria.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newGroup = AssetGroupModel(
      id: widget.group?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      displayInTree: _displayInTree,
      criteria: _nameController.text.trim().toLowerCase() == 'all'
          ? []
          : _criteria,
      users: _assignedUsers, // Pass users here for consistency
      companyId: _selectedCompanyId,
    );

    print('DEBUG: Number of criteria to save: ${_criteria.length}');
    print('DEBUG: Saving Group Data: ${jsonEncode(newGroup.toJson())}');

    final success = await ref
        .read(assetGroupProvider.notifier)
        .saveGroup(newGroup, users: _assignedUsers);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Group saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);
    final userState = ref.watch(userProvider);

    ref.listen<UserState>(userProvider, (previous, next) {
      if (previous?.currentUser == null && next.currentUser != null) {
        _checkSuperAdminAndLoadCompanies();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          widget.group == null ? 'Create User Group' : 'Edit User Group',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: state.isProcessing ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
              ),
              child: state.isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('SAVE GROUP'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralSection(),
              if (_nameController.text.trim().toLowerCase() != 'all') ...[
                const SizedBox(height: 32),
                _buildCriteriaSection(),
              ],
              const SizedBox(height: 32),
              _buildUserSection(userState),
              const SizedBox(height: 48),
              if (widget.group?.id != null &&
                  _nameController.text.trim().toLowerCase() != 'all')
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _showPreviewDialog,
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('PREVIEW MATCHING ASSETS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(UserState userState) {
    final allGroupUsers = userState.users.where((u) {
      final isSuper = u.roleId == 1 || (u.roleName ?? '').toLowerCase().replaceAll(' ', '').contains('superadmin');
      return u.companyId == _selectedCompanyId && !isSuper;
    }).toList();

    final isEditingAllGroup =
        _nameController.text.trim().toLowerCase() == 'all';

    // Auto-assign "All" group users if the group is currently empty and not manually cleared
    if (isEditingAllGroup &&
        _assignedUsers.isEmpty &&
        !_didAutoAssign &&
        !userState.isLoading &&
        allGroupUsers.isNotEmpty) {
      _didAutoAssign = true; // Mark as attempted
      for (var user in allGroupUsers) {
        if (!_assignedUsers.any((au) => au.userId == user.userId)) {
          _assignedUsers.add(
            AssetGroupUser(
              userId: user.userId,
              username: user.username,
              firstName: user.firstName,
              lastName: user.lastName,
              roleName: user.roleName,
              groupNames: user.groupNames?.join(', '),
            ),
          );
        }
      }
    }

    final eligibleUsers = userState.users.where((u) {
      final isAlreadyAssigned = _assignedUsers.any(
        (au) => au.userId == u.userId,
      );
      final isSuperAdmin = u.roleId == 1 ||
          (u.roleName ?? '').toLowerCase().replaceAll(' ', '').contains('superadmin');
      if (isSuperAdmin) return false;

      // If we are NOT editing the "All" group, exclude users who are already in the "All" group globally
      final isInAllGroupGlobally =
          u.groupNames?.any((n) => n.trim().toLowerCase() == 'all') ?? false;
      if (!isEditingAllGroup && isInAllGroupGlobally) return false;

      final isCorrectCompany = u.companyId == _selectedCompanyId;

      return !isAlreadyAssigned && isCorrectCompany;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'User Access Control',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (eligibleUsers.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var user in eligibleUsers) {
                        _assignedUsers.add(
                          AssetGroupUser(
                            userId: user.userId,
                            username: user.username,
                            firstName: user.firstName,
                            lastName: user.lastName,
                            roleName: user.roleName,
                            groupNames: user.groupNames?.join(', '),
                          ),
                        );
                      }
                      _selectedUserForAssignment = null;
                    });
                  },
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('ASSIGN ALL USERS'),
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_assignedUsers.length} Users Assigned',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('NAME', style: _headerStyle)),
                Expanded(
                  flex: 2,
                  child: Text('GROUP NAME', style: _headerStyle),
                ),
                Expanded(flex: 2, child: Text('ROLE', style: _headerStyle)),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Text(
                      'ACTION',
                      style: _headerStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User Rows
          if (_isLoadingDetails)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: primary),
              ),
            )
          else if (_assignedUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  'No users assigned to this group.',
                  style: GoogleFonts.inter(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final displayUsers = _assignedUsers;

                if (displayUsers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        'No users assigned to this group.',
                        style: GoogleFonts.inter(color: Colors.grey.shade500),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayUsers.length,
                  itemBuilder: (context, index) {
                    final assignment = displayUsers[index];
                    final user = userState.users.firstWhere(
                      (u) => u.userId == assignment.userId,
                      orElse: () => User(
                        userId: assignment.userId,
                        username: assignment.username,
                        email: '',
                        roleId: 0,
                        status: 1,
                      ),
                    );

                    final role = (assignment.roleName ?? user.roleName ?? '').toLowerCase();
                    final isRestricted =
                        role == 'customer' ||
                        role.contains('super admin') ||
                        role.contains('super_admin');

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isRestricted
                            ? const Color(0xFFF3F4F6)
                            : Colors.white,
                        border: const Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          // NAME
                          Expanded(
                            flex: 3,
                            child: Builder(
                              builder: (context) {
                                final fName = assignment.firstName ?? user.firstName ?? '';
                                final lName = assignment.lastName ?? user.lastName ?? '';
                                final fullName = (fName.isEmpty && lName.isEmpty)
                                    ? (user.fullName.isNotEmpty ? user.fullName : assignment.username)
                                    : '$fName $lName'.trim();
                                return Text(
                                  fullName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),

                          // GROUP NAME
                          Expanded(
                            flex: 2,
                            child: Builder(
                              builder: (context) {
                                final hasAll =
                                    user.groupNames?.any(
                                      (n) => n.trim().toLowerCase() == 'all',
                                    ) ??
                                    false;
                                if (hasAll) {
                                  return Text(
                                    'All',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.blue,
                                    ),
                                  );
                                }

                                final gNames =
                                    user.groupNames?.join(', ') ?? '';
                                return Text(
                                  gNames,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.blue,
                                  ),
                                );
                              },
                            ),
                          ),

                          // ROLE
                          Expanded(
                            flex: 2,
                            child: Text(
                              assignment.roleName ?? user.roleName ?? 'User',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),

                          SizedBox(
                            width: 48,
                            child: IconButton(
                              onPressed: () => setState(
                                () => _assignedUsers.remove(assignment),
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 16),

          // Add User Controls
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<User>(
                  value: eligibleUsers.contains(_selectedUserForAssignment)
                      ? _selectedUserForAssignment
                      : null,
                  hint: const Text('Select User'),
                  items: eligibleUsers.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text(
                        '${u.fullName} (${u.roleName ?? "User"})',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedUserForAssignment = v),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                    fillColor: Color(0xFFF9FAFB),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _selectedUserForAssignment == null
                    ? null
                    : () {
                        setState(() {
                          _assignedUsers.add(
                            AssetGroupUser(
                              userId: _selectedUserForAssignment!.userId,
                              username: _selectedUserForAssignment!.username,
                              firstName: _selectedUserForAssignment!.firstName,
                              lastName: _selectedUserForAssignment!.lastName,
                              roleName: _selectedUserForAssignment!.roleName,
                              groupNames: _selectedUserForAssignment!.groupNames
                                  ?.join(', '),
                            ),
                          );
                          _selectedUserForAssignment = null;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String label, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: value ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showPreviewDialog() async {
    await ref.read(assetGroupProvider.notifier).loadPreview(widget.group!.id!);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final preview = ref.watch(assetGroupProvider).previewAssets;
          return AlertDialog(
            title: const Text('Matching Assets Preview'),
            content: SizedBox(
              width: 600,
              height: 400,
              child: preview.isEmpty
                  ? const Center(
                      child: Text('No assets match the current criteria.'),
                    )
                  : ListView.builder(
                      itemCount: preview.length,
                      itemBuilder: (context, index) {
                        final asset = preview[index];
                        return ListTile(
                          leading: const Icon(Icons.storage),
                          title: Text(asset['tank_number'] ?? 'Unnamed Tank'),
                          subtitle: Text(
                            '${asset['plant_name']} - ${asset['city_name']}',
                          ),
                          trailing: Text(asset['device_id'] ?? '-'),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.layers,
                  color: primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'General Information',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              _buildTreeToggle(),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildLabelField(
                  'GROUP NAME',
                  TextFormField(
                    controller: _nameController,
                    readOnly: widget.group != null,
                    validator: (v) => v!.isEmpty ? 'Enter group name' : null,
                    decoration: _inputDecoration('e.g. All Battery Tanks'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabelField(
            'DESCRIPTION',
            TextFormField(
              controller: _descriptionController,
              readOnly: widget.group != null,
              maxLines: 2,
              decoration: _inputDecoration('Briefly describe this group...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeToggle() {
    return InkWell(
      onTap: () => setState(() => _displayInTree = !_displayInTree),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _displayInTree
              ? const Color(0xFFECFDF5)
              : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _displayInTree
                ? const Color(0xFF10B981).withOpacity(0.2)
                : const Color(0xFFEF4444).withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _displayInTree
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 14,
              color: _displayInTree
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              _displayInTree ? 'ACTIVE' : 'INACTIVE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _displayInTree
                    ? const Color(0xFF059669)
                    : const Color(0xFFDC2626),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeStatusBadge(bool visible) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visible ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: visible
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visible ? Icons.account_tree_outlined : Icons.account_tree_rounded,
            size: 14,
            color: visible ? const Color(0xFF059669) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4),
          Text(
            visible ? 'ACTIVE' : 'INACTIVE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: visible
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asset Selection Criteria',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define the dynamic rules that populate this group.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _criteria.clear();
                      });
                    },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('CLEAR ALL'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
          if (_criteria.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No selection criteria added.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            _buildCriteriaHeader(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _criteria.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) => _buildCriteriaRow(index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriteriaHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('PARAMETER', style: _headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text('LOGIC', style: _headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Text('VALUE', style: _headerStyle)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text('AND/OR', style: _headerStyle)),
          const SizedBox(width: 12),
          const SizedBox(
            width: 48,
            child: Center(
              child: Text(
                'CLEAR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF6B7280),
    letterSpacing: 0.5,
  );

  Widget _buildCriteriaValueField(int index) {
    final rule = _criteria[index];

    if (rule.parameter == 'Product') {
      final state = ref.watch(productNotifierProvider);
      final products = state.products.map((p) {
        return {
          'id': p.id.toString(),
          'name': p.name,
        };
      }).toList();

      products.sort((a, b) => a['name']!.compareTo(b['name']!));

      // Filter out products selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Product' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredProducts = products
          .where((p) => 
              (!selectedVals.contains(p['id']) && !selectedVals.contains(p['name'])) || 
              p['id'] == rule.value || 
              p['name'] == rule.value)
          .toList();

      final matchIndex = filteredProducts.indexWhere((p) => p['id'] == rule.value || p['name'] == rule.value);
      final dropdownValue = matchIndex != -1 ? filteredProducts[matchIndex]['id'] : null;

      return DropdownButtonFormField<String>(
        value: dropdownValue,
        items: filteredProducts
            .map(
              (p) => DropdownMenuItem<String>(
                value: p['id'] as String,
                child: Text(p['name']!, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Product',
        ),
      );
    }

    if (rule.parameter == 'City') {

      final siteCities = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.city)
          .whereType<String>();
      final cities = <String>{ ...siteCities}.toList()..sort();

      // Filter out cities selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'City' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredCities = cities
          .where((c) => !selectedVals.contains(c) || c == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        value: filteredCities.contains(rule.value) ? rule.value : null,
        items: filteredCities
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select City',
        ),
      );
    }

    if (rule.parameter == 'Country') {

      final siteCountries = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.country)
          .whereType<String>();
      final countries = <String>{...siteCountries}.toList()
        ..sort();

      // Filter out countries selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Country' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredCountries = countries
          .where((c) => !selectedVals.contains(c) || c == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        value: filteredCountries.contains(rule.value) ? rule.value : null,
        items: filteredCountries
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Country',
        ),
      );
    }

    if (rule.parameter == 'State or Province') {

      final siteStates = ref
          .watch(siteNotifierProvider)
          .groupedSites
          .expand((g) => g.addresses)
          .map((a) => a.state)
          .whereType<String>();
      final states = <String>{...siteStates}.toList()..sort();

      // Filter out states selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'State or Province' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredStates = states
          .where((s) => !selectedVals.contains(s) || s == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        value: filteredStates.contains(rule.value) ? rule.value : null,
        items: filteredStates
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select State/Province',
        ),
      );
    }

    if (rule.parameter == 'DeviceID') {
      final devices = ref
          .watch(deviceNotifierProvider)
          .groupedDevices
          .expand((g) => g.devices)
          .map((d) => {'id': d.id.toString(), 'name': d.deviceId})
          .toList();
      devices.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      // Filter out devices selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'DeviceID' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredDevices = devices
          .where((d) => 
              (!selectedVals.contains(d['id']) && !selectedVals.contains(d['name'])) || 
              d['id'] == rule.value || 
              d['name'] == rule.value)
          .toList();

      final matchIndex = filteredDevices.indexWhere((d) => d['id'] == rule.value || d['name'] == rule.value);
      final dropdownValue = matchIndex != -1 ? filteredDevices[matchIndex]['id'] : null;

      return DropdownButtonFormField<String>(
        value: dropdownValue,
        items: filteredDevices
            .map(
              (d) => DropdownMenuItem<String>(
                value: d['id'] as String,
                child: Text(
                  d['name'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Device ID',
        ),
      );
    }

    if (rule.parameter == 'Site Name') {
      final siteState = ref.watch(siteNotifierProvider);
      final sites = siteState.groupedSites
          .map((g) => g.name)
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (sites.isEmpty && siteState.isLoading) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Loading sites...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Site Name',
          ),
        );
      }

      if (sites.isEmpty) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [
            DropdownMenuItem(value: null, child: Text('No sites found')),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Site Name',
          ),
        );
      }

      // Filter out sites selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Site Name' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredSites = sites
          .where((s) => !selectedVals.contains(s) || s == rule.value)
          .toList();

      return DropdownButtonFormField<String>(
        value: filteredSites.contains(rule.value) ? rule.value : null,
        items: filteredSites
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Site Name',
        ),
      );
    }

    if (rule.parameter == 'Tank Name') {
      final tankState = ref.watch(tankNotifierProvider);
      final tanks = tankState.groupedTanks
          .expand((g) => g.tanks)
          .map(
            (t) => {
              'id': t.tankId.toString(),
              'name': t.tankName ?? t.tankNumber,
            },
          )
          .toList();
      tanks.sort((a, b) => a['name']!.compareTo(b['name']!));

      if (tanks.isEmpty && tankState.isLoading) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Loading tanks...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tank Name',
          ),
        );
      }

      if (tanks.isEmpty) {
        return DropdownButtonFormField<String>(
          value: null,
          items: const [
            DropdownMenuItem(value: null, child: Text('No tanks found')),
          ],
          onChanged: null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tank Name',
          ),
        );
      }

      // Filter out tanks selected in other rows
      final selectedVals = _criteria
          .asMap()
          .entries
          .where((e) => e.key != index && e.value.parameter == 'Tank Name' && e.value.value.isNotEmpty)
          .map((e) => e.value.value)
          .toSet();

      final filteredTanks = tanks
          .where((t) => 
              (!selectedVals.contains(t['id']) && !selectedVals.contains(t['name'])) || 
              t['id'] == rule.value || 
              t['name'] == rule.value)
          .toList();

      final matchIndex = filteredTanks.indexWhere((t) => t['id'] == rule.value || t['name'] == rule.value);
      final dropdownValue = matchIndex != -1 ? filteredTanks[matchIndex]['id'] : null;

      return DropdownButtonFormField<String>(
        value: dropdownValue,
        items: filteredTanks
            .map(
              (t) => DropdownMenuItem<String>(
                value: t['id'] as String,
                child: Text(t['name']!, style: GoogleFonts.inter(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => rule.value = v!),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Select Tank Name',
        ),
      );
    }

    return TextFormField(
      initialValue: rule.value,
      key: ValueKey('rule_val_${index}_${rule.parameter}'),
      onChanged: (v) => setState(() => rule.value = v),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Value',
      ),
    );
  }

  Widget _buildCriteriaRow(int index) {
    final rule = _criteria[index];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // 1. PARAMETER
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              value: rule.parameter,
              items: _parameters
                  .where((p) {
                    if (index < 3) {
                      return true;
                    } else {
                      final isSelectedInFirstThree = _criteria.asMap().entries.any(
                            (e) => e.key < 3 && e.value.parameter == p,
                          );
                      return !isSelectedInFirstThree || p == rule.parameter;
                    }
                  })
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (index < _initialCriteriaCount &&
                          !(ref.watch(userProvider).currentUser?.roleId == 1 ||
                            ref.watch(userProvider).currentUser?.roleId == 2))
                  ? null
                  : (v) {
                      setState(() {
                        rule.parameter = v!;
                        rule.value = '';
                      });
                    },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. LOGIC
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _logics.contains(rule.logic)
                  ? rule.logic
                  : (_logics.contains('=') ? '=' : _logics.first),
              items: _logics
                  .map(
                    (l) => DropdownMenuItem(
                      value: l,
                      child: Text(l, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => rule.logic = v!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 3. VALUE
          Expanded(flex: 4, child: _buildCriteriaValueField(index)),
          const SizedBox(width: 12),

          // 4. AND/OR
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _operators.contains(rule.operator)
                  ? rule.operator
                  : _operators.first,
              items: _operators
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => rule.operator = v!),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(),
                fillColor: Color(0xFFF3F4FF),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 12),

          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _removeCriteria(index),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
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
            color: primary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        field,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
        focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
