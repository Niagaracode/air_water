import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Features
import '../../../asset_group/domain/models/asset_group_model.dart';
import '../../../asset_group/presentation/controller/asset_group_provider.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';
import '../controller/roaster_provider.dart';
import '../../../message_template/presentation/controller/message_template_provider.dart';

// Shared
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/app_theme/app_theme.dart';

class AddRosterGroupModal extends ConsumerStatefulWidget {
  final CompanyAutocomplete? initialCompany;
  const AddRosterGroupModal({super.key, this.initialCompany});

  @override
  ConsumerState<AddRosterGroupModal> createState() =>
      _AddRosterGroupModalState();
}

class _AddRosterGroupModalState extends ConsumerState<AddRosterGroupModal> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _companyAutocompleteController = TextEditingController();
  final _companyFocusNode = FocusNode();

  CompanyAutocomplete? _selectedCompany;

  // Assigned users and their notification config
  final List<AssetGroupUser> _assignedUsers = [];
  final Map<int, _UserConfig> _userConfigs = {};
  User? _selectedUserToAdd;

  // Companies loaded for super admin
  List<CompanyAutocomplete> _companies = [];
  bool _isLoadingCompanies = false;

  // Users loaded for the selected company
  List<User> _companyUsers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill company if provided (e.g. opened from Add User form)
    if (widget.initialCompany != null) {
      _selectedCompany = widget.initialCompany;
      _companyAutocompleteController.text = widget.initialCompany!.name;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load message templates
      ref.read(messageTemplateProvider.notifier).loadTemplates();

      final currentUser = ref.read(userProvider).currentUser;
      final isSuperAdmin = currentUser?.roleId == 1;

      if (isSuperAdmin) {
        await _loadCompanies();
        if (_selectedCompany == null) {
          final company = CompanyAutocomplete(
            id: 216,
            name: 'Air Water',
          );
          if (mounted) {
            setState(() {
              _selectedCompany = company;
              _companyAutocompleteController.text = company.name;
            });
            await _loadCompanyUsers(company.id);
          }
        }
      }

      // For non-super-admin: auto-set their company
      if (widget.initialCompany == null &&
          currentUser != null &&
          currentUser.roleId != 1 &&
          currentUser.companyId != null) {
        final company = CompanyAutocomplete(
          id: currentUser.companyId!,
          name: currentUser.companyName ?? '',
        );
        if (mounted) {
          setState(() {
            _selectedCompany = company;
            _companyAutocompleteController.text = company.name;
          });
          await _loadCompanyUsers(company.id);
        }
        return;
      }

      // If a company was already pre-selected, load its users
      if (_selectedCompany != null && mounted) {
        await _loadCompanyUsers(_selectedCompany!.id);
      }
    });
  }

  Future<void> _loadCompanies() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCompanies = true;
    });
    try {
      final results = await ref.read(userProvider.notifier).searchCompanies('');
      if (mounted) {
        setState(() {
          _companies = results;
          // Ensure widget.initialCompany is in the list
          if (widget.initialCompany != null &&
              !_companies.any((c) => c.id == widget.initialCompany!.id)) {
            _companies.insert(0, widget.initialCompany!);
          }
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
      if (mounted) {
        setState(() {
          _companies = widget.initialCompany != null ? [widget.initialCompany!] : [];
          _isLoadingCompanies = false;
        });
      }
    }
  }

  Future<void> _loadCompanyUsers(int companyId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingUsers = true;
      _companyUsers = [];
      _selectedUserToAdd = null;
    });
    try {
      final repository = ref.read(userRepositoryProvider);
      final response = await repository.searchUsers(
        page: 1,
        companyId: companyId,
      );
      if (mounted) {
        setState(() {
          _companyUsers = response.data;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading company users: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _companyAutocompleteController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final groupName = _nameController.text.trim();

    if (groupName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter Group Name')),
      );
      return;
    }

    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser == null) return;

    final newGroup = AssetGroupModel(
      name: groupName,
      description: _descController.text.trim(),
      displayInTree: true,
      status: 1,
      domain: 'ROSTER',
      siteId: null,
      parameterName: null,
      criteria: const [],
      companyId: _selectedCompany?.id ?? currentUser.companyId,
    );

    final createdId = await ref
        .read(assetGroupProvider.notifier)
        .saveGroupAndGetId(newGroup, users: _assignedUsers);

    if (!mounted) return;

    if (createdId != null) {
      final rosterNotifier = ref.read(roasterNotifierProvider.notifier);
      for (final cfg in _userConfigs.values) {
        await rosterNotifier.createRoster({
          'description': groupName,
          'enabled': 1,
          'parameter_name': 'LEVEL',
          'company_id': _selectedCompany?.id ?? currentUser.companyId,
          if (cfg.messageTemplateId != null)
            'message_template_id': cfg.messageTemplateId,
          'roster_group_id': createdId,
          'members': [
            {
              'user_id': cfg.userId,
              'email_notif': cfg.email ? 1 : 0,
              'push_notif': cfg.push ? 1 : 0,
              'email_to_phone': cfg.sms ? 1 : 0,
              'enabled': cfg.enabled ? 1 : 0,
              'parameter_name': 'LEVEL',
              if (cfg.messageTemplateId != null)
                'message_template_id': cfg.messageTemplateId,
            },
          ],
        });
      }

      if (!mounted) return;
      ref.read(rosterGroupProvider.notifier).loadGroups();
      Navigator.of(context).pop(createdId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Roster group created successfully')),
      );
    } else {
      final error = ref.read(assetGroupProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Failed to create group: ${error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addSelectedUser() {
    if (_selectedUserToAdd == null) return;
    setState(() {
      _assignedUsers.add(AssetGroupUser(
        userId: _selectedUserToAdd!.userId,
        username: _selectedUserToAdd!.username,
        firstName: _selectedUserToAdd!.firstName,
        lastName: _selectedUserToAdd!.lastName,
        roleName: _selectedUserToAdd!.roleName,
      ));
      _userConfigs[_selectedUserToAdd!.userId] = _UserConfig(
        userId: _selectedUserToAdd!.userId,
      );
      _selectedUserToAdd = null;
    });
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);
    final currentUser = ref.watch(userProvider).currentUser;
    final isSuperAdmin = currentUser?.roleId == 1;

    final eligibleUsers = _companyUsers.where((u) {
      final alreadyAdded = _assignedUsers.any((a) => a.userId == u.userId);
      return !alreadyAdded && u.roleId != 1;
    }).toList();

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: SafeArea(
          child: SizedBox(
            width: MediaQuery.of(context).size.width < 640 ? MediaQuery.of(context).size.width : 640,
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 40,
                    vertical: MediaQuery.of(context).size.width < 600 ? 24 : 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Roster Group',
                                style: GoogleFonts.outfit(
                                  fontSize: MediaQuery.of(context).size.width < 600 ? 22 : 26,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Define group info and assign users with notifications.',
                                style: GoogleFonts.inter(
                                  fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── GROUP NAME ─────────────────────────────────────
                    _buildLabel('GROUP NAME*'),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _nameController,
                      hint: 'e.g. Battery Maintenance Group',
                    ),
                    const SizedBox(height: 24),

                    // ── DESCRIPTION ────────────────────────────────────
                    _buildLabel('DESCRIPTION'),
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _descController,
                      hint: 'e.g. Roster group for notifications',
                    ),
                    const SizedBox(height: 24),

                    // ── ASSIGN USERS (always visible) ──────────────────
                    _buildLabel('ASSIGN USERS'),
                    const SizedBox(height: 10),

                    // User selector row: dropdown + Add button
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 500;
                        final dropdownField = _selectedCompany == null
                            ? _buildDisabledDropdown(
                          isSuperAdmin
                              ? 'Select a company first…'
                              : 'Loading users…',
                        )
                            : _isLoadingUsers
                            ? _buildLoadingDropdown()
                            : _buildUserDropdown(eligibleUsers);

                        final addButton = SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed:
                            (_selectedCompany == null ||
                                _selectedUserToAdd == null ||
                                _isLoadingUsers)
                                ? null
                                : _addSelectedUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              const Color(0xFFE5E7EB),
                              disabledForegroundColor:
                              const Color(0xFF9CA3AF),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.person_add_alt_1,
                                size: 18),
                            label: Text(
                              'Add User',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );

                        if (isNarrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              dropdownField,
                              const SizedBox(height: 12),
                              addButton,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: dropdownField),
                            const SizedBox(width: 12),
                            addButton,
                          ],
                        );
                      },
                    ),

                    // Hint when company users are empty
                    if (_selectedCompany != null &&
                        !_isLoadingUsers &&
                        _companyUsers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 6),
                            Text(
                              'No users found for this company.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Assigned users notification table ───────────────
                    if (_assignedUsers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 550;
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                Border.all(color: const Color(0xFFDDE1FF)),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Sub-header
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_active_outlined,
                                        size: 15,
                                        color: primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'NOTIFICATION SETTINGS',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: primary
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_assignedUsers.length} user${_assignedUsers.length == 1 ? '' : 's'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),

                                  // Column headers
                                  if (!isMobile) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'USER',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF6B7280),
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                        _tableHeader('EMAIL'),
                                        _tableHeader('PUSH'),
                                        _tableHeader('SMS'),
                                        _tableHeaderWide('TEMPLATE'),
                                        const SizedBox(width: 36),
                                      ],
                                    ),
                                    const Divider(height: 1),
                                  ],

                                  // User rows
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                    const NeverScrollableScrollPhysics(),
                                    itemCount: _assignedUsers.length,
                                    separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                    itemBuilder: (_, i) =>
                                        _buildUserRow(_assignedUsers[i], isMobile),
                                  ),
                                ],
                              ),
                            );
                          }
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── CREATE GROUP button ─────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isProcessing ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: state.isProcessing
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          'CREATE GROUP',
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
          ),
        ),
    );
  }

  // ─── Disabled placeholder dropdown ────────────────────────────────────────
  Widget _buildDisabledDropdown(String hint) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.person_search_outlined,
              size: 18, color: Color(0xFFD1D5DB)),
          const SizedBox(width: 8),
          Text(
            hint,
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFFD1D5DB)),
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down,
              color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  // ─── Loading state dropdown ────────────────────────────────────────────────
  Widget _buildLoadingDropdown() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF9FAFB),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading users…',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ─── User selector dropdown ────────────────────────────────────────────────
  Widget _buildUserDropdown(List<User> eligibleUsers) {
    return DropdownButtonFormField<User>(
      isExpanded: true,
      itemHeight: 56,
      value: eligibleUsers.contains(_selectedUserToAdd)
          ? _selectedUserToAdd
          : null,
      selectedItemBuilder: (BuildContext context) {
        return eligibleUsers.map<Widget>((u) {
          final parts = [u.firstName, u.lastName]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList();
          final displayName =
              parts.isNotEmpty ? parts.join(', ') : u.username;
          return Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor:
                    primary.withValues(alpha: 0.08),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }).toList();
      },
      hint: Text(
        eligibleUsers.isEmpty
            ? 'All users already assigned'
            : 'Select a user to assign…',
        style:
            GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
      ),
      items: eligibleUsers.map((u) {
        final parts = [u.firstName, u.lastName]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
        final displayName =
            parts.isNotEmpty ? parts.join(', ') : u.username;
        return DropdownMenuItem(
          value: u,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    primary.withValues(alpha: 0.08),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      u.roleName ?? 'User',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: eligibleUsers.isEmpty
          ? null
          : (v) => setState(() => _selectedUserToAdd = v),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: primary, width: 1.5),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  // ─── Single assigned user row ──────────────────────────────────────────────
  Widget _buildUserRow(AssetGroupUser user, bool isMobile) {
    final cfg = _userConfigs[user.userId]!;
    final parts = [user.firstName, user.lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final displayName =
        parts.isNotEmpty ? parts.join(', ') : user.username;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: primary.withValues(alpha: 0.08),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.roleName != null)
                        Text(
                          user.roleName!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _assignedUsers.removeWhere((g) => g.userId == user.userId);
                      _userConfigs.remove(user.userId);
                    });
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMobileToggle('EMAIL', cfg.email, (v) {
                  setState(() => _userConfigs[user.userId] = cfg.copyWith(email: v));
                }),
                _buildMobileToggle('PUSH', cfg.push, (v) {
                  setState(() => _userConfigs[user.userId] = cfg.copyWith(push: v));
                }),
                _buildMobileToggle('SMS', cfg.sms, (v) {
                  setState(() => _userConfigs[user.userId] = cfg.copyWith(sms: v));
                }),
              ],
            ),
            const SizedBox(height: 12),
            _buildMobileTemplateDropdown(cfg, user),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar + name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor:
                      primary.withValues(alpha: 0.08),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.roleName != null)
                        Text(
                          user.roleName!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Email toggle
          _toggle(cfg.email, (v) {
            setState(() =>
                _userConfigs[user.userId] = cfg.copyWith(email: v));
          }),

          // Push toggle
          _toggle(cfg.push, (v) {
            setState(
                () => _userConfigs[user.userId] = cfg.copyWith(push: v));
          }),

          // SMS toggle
          _toggle(cfg.sms, (v) {
            setState(
                () => _userConfigs[user.userId] = cfg.copyWith(sms: v));
          }),

          // Template dropdown
          SizedBox(
            width: 140,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: cfg.messageTemplateId,
                  hint: Text(
                    'Template',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF9CA3AF)),
                  ),
                  icon:
                      const Icon(Icons.arrow_drop_down, size: 16),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text('None',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280))),
                    ),
                    ...ref
                        .watch(messageTemplateProvider)
                        .templates
                        .map((t) => DropdownMenuItem<int>(
                              value: t.id,
                              child: Text(
                                t.name,
                                style: GoogleFonts.inter(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _userConfigs[user.userId] = cfg.copyWith(
                        messageTemplateId: v,
                        clearTemplate: v == null,
                      );
                    });
                  },
                ),
              ),
            ),
          ),

          // Remove button
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _assignedUsers
                      .removeWhere((g) => g.userId == user.userId);
                  _userConfigs.remove(user.userId);
                });
              },
              icon: const Icon(Icons.close_rounded,
                  color: Colors.red, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }




  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: const Color(0xFF374151),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _tableHeader(String text) {
    return SizedBox(
      width: 60,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _tableHeaderWide(String text) {
    return SizedBox(
      width: 140,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _toggle(bool value, ValueChanged<bool> onChanged) {
    return SizedBox(
      width: 60,
      child: Center(
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: primary,
          activeThumbColor: Colors.white,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE5E7EB),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildMobileToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: primary,
          activeThumbColor: Colors.white,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE5E7EB),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildMobileTemplateDropdown(_UserConfig cfg, AssetGroupUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: cfg.messageTemplateId,
          hint: Text(
            'Select message template…',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
          ),
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: [
            DropdownMenuItem<int>(
              value: null,
              child: Text(
                'No template',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
              ),
            ),
            ...ref
                .watch(messageTemplateProvider)
                .templates
                .map((t) => DropdownMenuItem<int>(
                      value: t.id,
                      child: Text(
                        t.name,
                        style: GoogleFonts.inter(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
          ],
          onChanged: (v) {
            setState(() {
              _userConfigs[user.userId] = cfg.copyWith(
                messageTemplateId: v,
                clearTemplate: v == null,
              );
            });
          },
        ),
      ),
    );
  }
}

// ─── Per-user notification config ─────────────────────────────────────────────
class _UserConfig {
  final int userId;
  final bool email;
  final bool push;
  final bool sms;
  final bool enabled;
  final int? messageTemplateId;

  const _UserConfig({
    required this.userId,
    this.email = false,
    this.push = false,
    this.sms = false,
    this.enabled = true,
    this.messageTemplateId,
  });

  _UserConfig copyWith({
    bool? email,
    bool? push,
    bool? sms,
    bool? enabled,
    int? messageTemplateId,
    bool clearTemplate = false,
  }) {
    return _UserConfig(
      userId: userId,
      email: email ?? this.email,
      push: push ?? this.push,
      sms: sms ?? this.sms,
      enabled: enabled ?? this.enabled,
      messageTemplateId: clearTemplate
          ? null
          : (messageTemplateId ?? this.messageTemplateId),
    );
  }
}
