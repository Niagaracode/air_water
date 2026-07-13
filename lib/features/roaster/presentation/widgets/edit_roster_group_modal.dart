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
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/network/http/api_service.dart';
import '../../../../core/app_theme/app_theme.dart';

class EditRosterGroupModal extends ConsumerStatefulWidget {
  final AssetGroupModel group;
  const EditRosterGroupModal({super.key, required this.group});

  @override
  ConsumerState<EditRosterGroupModal> createState() =>
      _EditRosterGroupModalState();
}

class _EditRosterGroupModalState extends ConsumerState<EditRosterGroupModal> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  final _companyAutocompleteController = TextEditingController();
  final _companyFocusNode = FocusNode();

  CompanyAutocomplete? _selectedCompany;

  List<AssetGroupUser> _groupUsers = [];
  final Map<int, _UserConfig> _userConfigs = {};
  List<int> _selectedRosterIds = [];
  String _parameter = 'LEVEL';
  bool _savingRoster = false;
  User? _selectedUserToAdd;

  List<CompanyAutocomplete> _companies = [];
  bool _isLoadingCompanies = false;
  List<User> _companyUsers = [];
  bool _isLoadingUsers = false;
  bool _loadingUsers = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descController = TextEditingController(text: widget.group.description);
    _selectedCompany = widget.group.companyId != null
        ? CompanyAutocomplete(
            id: widget.group.companyId!,
            name: widget.group.companyName ?? '',
          )
        : null;
    if (_selectedCompany != null) {
      _companyAutocompleteController.text = _selectedCompany!.name;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(messageTemplateProvider.notifier).loadTemplates();

      final currentUser = ref.read(userProvider).currentUser;
      final isSuperAdmin = currentUser?.roleId == 1;

      if (isSuperAdmin) {
        await _loadCompanies();
      }

      await _loadGroupDetailsAndConfigs();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _companyAutocompleteController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
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
          if (_selectedCompany != null &&
              !_companies.any((c) => c.id == _selectedCompany!.id)) {
            _companies.insert(0, _selectedCompany!);
          }
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
      if (mounted) {
        setState(() {
          _companies = _selectedCompany != null ? [_selectedCompany!] : [];
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

  Future<void> _loadGroupDetailsAndConfigs() async {
    if (!mounted) return;
    setState(() {
      _loadingUsers = true;
      _groupUsers = [];
      _userConfigs.clear();
      _selectedRosterIds.clear();
      _selectedUserToAdd = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get('/asset-groups/${widget.group.id}');
      final detail = AssetGroupModel.fromJson(resp.data['data']);

      Map<int, _UserConfig> savedConfigs = {};
      List<AssetGroupUser> loadedUsers = [];
      String savedParam = 'LEVEL';
      List<int> rosterIds = [];
      List? rosters;

      try {
        var rosterResp = await client.get(
          '/roster',
          query: {'roster_group_id': widget.group.id, 'limit': 100},
        );
        rosters = rosterResp.data['data'] as List?;

        if (rosters == null || rosters.isEmpty) {
          rosterResp = await client.get(
            '/roster',
            query: {'description': widget.group.name, 'limit': 100},
          );
          rosters = rosterResp.data['data'] as List?;
        }

        if (rosters != null && rosters.isNotEmpty) {
          savedParam = rosters.first['parameter_name'] ?? 'LEVEL';

          for (final roster in rosters) {
            final id = roster['id'];
            if (id != null) {
              rosterIds.add(id as int);
            }
            final membersResp = await client.get(
              '/roster/${roster['id']}/members',
            );
            final members = membersResp.data['data'] as List?;
            if (members != null) {
              for (final m in members) {
                final uid = m['user_id'];
                if (uid != null) {
                  if (!savedConfigs.containsKey(uid)) {
                    savedConfigs[uid] = _UserConfig(
                      userId: uid,
                      email: (m['email_notif'] ?? 0) == 1,
                      push: (m['push_notif'] ?? 0) == 1,
                      sms: (m['email_to_phone'] ?? 0) == 1,
                      enabled: (m['enabled'] ?? 0) == 1,
                      messageTemplateId: m['message_template_id'] as int?,
                    );

                    loadedUsers.add(
                      AssetGroupUser(
                        userId: uid,
                        username: m['username'] ?? '',
                        firstName: m['first_name'],
                        lastName: m['last_name'],
                        roleName: m['role_name'],
                      ),
                    );
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching existing roster settings: $e');
      }

      if (mounted) {
        setState(() {
          _nameController.text = detail.name;
          _descController.text = detail.description;
          _selectedCompany = detail.companyId != null
              ? CompanyAutocomplete(
                  id: detail.companyId!,
                  name: detail.companyName ?? '',
                )
              : null;
          if (_selectedCompany != null) {
            _companyAutocompleteController.text = _selectedCompany!.name;
          }

          _userConfigs.clear();
          for (final gu in loadedUsers) {
            _userConfigs[gu.userId] = savedConfigs[gu.userId]!;
          }
          _groupUsers = loadedUsers;

          _loadingUsers = false;
          _parameter = (savedParam != 'LEVEL')
              ? savedParam
              : (detail.parameterName ?? 'LEVEL');
          _selectedRosterIds = rosterIds;
          _selectedUserToAdd = null;
        });

        final companyId = _selectedCompany?.id;
        if (companyId != null) {
          _loadCompanyUsers(companyId);
        }
      }
    } catch (e) {
      debugPrint('Error loading group configs: $e');
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _saveRosters() async {
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

    if (currentUser.roleId == 1 && _selectedCompany == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Company')),
      );
      return;
    }

    setState(() => _savingRoster = true);

    int? siteId;
    for (final criterion in widget.group.criteria) {
      if (criterion.parameter == 'site_id') {
        siteId = int.tryParse(criterion.value);
        break;
      }
    }

    final updatedGroup = AssetGroupModel(
      id: widget.group.id,
      name: groupName,
      description: _descController.text.trim(),
      displayInTree: widget.group.displayInTree,
      status: widget.group.status,
      domain: widget.group.domain,
      criteria: widget.group.criteria,
      companyId: _selectedCompany?.id ?? currentUser.companyId,
      companyName: _selectedCompany?.name,
      siteId: widget.group.siteId,
      parameterName: widget.group.parameterName,
      tankId: widget.group.tankId,
    );

    final savedId = await ref
        .read(assetGroupProvider.notifier)
        .saveGroupAndGetId(updatedGroup, users: _groupUsers);

    if (savedId == null) {
      if (mounted) {
        setState(() => _savingRoster = false);
        final error = ref.read(assetGroupProvider).error;
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save group: ${error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final rosterNotifier = ref.read(roasterNotifierProvider.notifier);
    for (final id in _selectedRosterIds) {
      await rosterNotifier.deleteRoaster(id);
    }

    int created = 0;
    for (final cfg in _userConfigs.values) {
      final userOpt = _groupUsers.where((u) => u.userId == cfg.userId);
      if (userOpt.isEmpty) continue;
      final user = userOpt.first;

      final data = {
        'description': '$groupName – ${user.username}',
        'enabled': cfg.enabled ? 1 : 0,
        'parameter_name': _parameter,
        'company_id': _selectedCompany?.id ?? currentUser.companyId,
        if (siteId != null) 'site_id': siteId,
        if (cfg.messageTemplateId != null)
          'message_template_id': cfg.messageTemplateId,
        'roster_group_id': savedId,
        'members': [
          {
            'user_id': cfg.userId,
            'email_notif': cfg.email ? 1 : 0,
            'push_notif': cfg.push ? 1 : 0,
            'email_to_phone': cfg.sms ? 1 : 0,
            'enabled': cfg.enabled ? 1 : 0,
            'parameter_name': _parameter,
            if (siteId != null) 'site_id': siteId,
            if (cfg.messageTemplateId != null)
              'message_template_id': cfg.messageTemplateId,
          },
        ],
      };
      final ok = await rosterNotifier.createRoster(data);
      if (ok) created++;
    }

    ref.read(rosterGroupProvider.notifier).loadGroups();

    if (mounted) {
      setState(() => _savingRoster = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Roster group and $created user configuration(s) updated successfully',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = ref.watch(userProvider).currentUser?.roleId == 1;

    final eligibleUsers = _companyUsers.where((u) {
      final alreadyAdded = _groupUsers.any((a) => a.userId == u.userId);
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
        child: SizedBox(
          width: 640,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                ),
              ),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.group.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Edit roster group details and configurations',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // GROUP NAME
                      _buildLabel('GROUP NAME*'),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _nameController,
                        hint: 'e.g. Battery Maintenance Group',
                      ),
                      const SizedBox(height: 24),

                      // DESCRIPTION
                      _buildLabel('DESCRIPTION'),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _descController,
                        hint: 'e.g. Roster group for notifications',
                      ),
                      const SizedBox(height: 24),

                      // COMPANY (Super Admin only)
                      if (isSuperAdmin) ...[
                        _buildLabel('COMPANY*'),
                        const SizedBox(height: 10),
                        _buildCompanyDropdown(),
                        const SizedBox(height: 24),
                      ],

                      _buildLabel('ASSIGN USERS'),
                      const SizedBox(height: 10),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _selectedCompany == null
                                ? _buildDisabledDropdown(
                                    isSuperAdmin
                                        ? 'Select a company first…'
                                        : 'Loading users…',
                                  )
                                : _isLoadingUsers
                                ? _buildLoadingDropdown()
                                : _buildUserDropdown(eligibleUsers),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_selectedCompany == null ||
                                      _selectedUserToAdd == null ||
                                      _isLoadingUsers)
                                  ? null
                                  : () {
                                      setState(() {
                                        _groupUsers.add(
                                          AssetGroupUser(
                                            userId: _selectedUserToAdd!.userId,
                                            username:
                                                _selectedUserToAdd!.username,
                                            firstName:
                                                _selectedUserToAdd!.firstName,
                                            lastName:
                                                _selectedUserToAdd!.lastName,
                                            roleName:
                                                _selectedUserToAdd!.roleName,
                                          ),
                                        );
                                        _userConfigs[_selectedUserToAdd!
                                            .userId] = _UserConfig(
                                          userId: _selectedUserToAdd!.userId,
                                        );
                                        _selectedUserToAdd = null;
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFFE5E7EB,
                                ),
                                disabledForegroundColor: const Color(
                                  0xFF9CA3AF,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.person_add_alt_1,
                                size: 18,
                              ),
                              label: Text(
                                'Add User',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_selectedCompany != null &&
                          !_isLoadingUsers &&
                          _companyUsers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Color(0xFF9CA3AF),
                              ),
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

                      if (_loadingUsers)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_groupUsers.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDE1FF)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_groupUsers.length} user${_groupUsers.length == 1 ? '' : 's'}',
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
                                  _headerCell('EMAIL'),
                                  _headerCell('PUSH'),
                                  _headerCell('SMS'),
                                  _templateHeaderCell('TEMPLATE'),
                                  const SizedBox(width: 36),
                                ],
                              ),
                              const Divider(height: 1),

                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _groupUsers.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) =>
                                    _buildUserRow(_groupUsers[i]),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _savingRoster ? null : _saveRosters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _savingRoster
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'SAVE CHANGES',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
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

  Widget _headerCell(String text) {
    return SizedBox(
      width: 60,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _templateHeaderCell(String text) {
    return SizedBox(
      width: 140,
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildUserRow(AssetGroupUser user) {
    final cfg = _userConfigs[user.userId]!;
    final fullName = [
      user.firstName,
      user.lastName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    final displayName = fullName.isNotEmpty ? fullName : user.username;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
          _toggle(cfg.email, (v) {
            setState(() => _userConfigs[user.userId] = cfg.copyWith(email: v));
          }),
          _toggle(cfg.push, (v) {
            setState(() => _userConfigs[user.userId] = cfg.copyWith(push: v));
          }),
          _toggle(cfg.sms, (v) {
            setState(() => _userConfigs[user.userId] = cfg.copyWith(sms: v));
          }),
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: cfg.messageTemplateId,
                hint: Text(
                  'Select Template',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
                icon: const Icon(Icons.arrow_drop_down, size: 16),
                items: [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      'None',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...ref.watch(messageTemplateProvider).templates.map((t) {
                    return DropdownMenuItem<int>(
                      value: t.id,
                      child: Text(
                        t.name,
                        style: GoogleFonts.inter(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
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
          SizedBox(
            width: 36,
            child: Center(
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _groupUsers.removeWhere((gu) => gu.userId == user.userId);
                    _userConfigs.remove(user.userId);
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
        ],
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
          const Icon(
            Icons.person_search_outlined,
            size: 18,
            color: Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 8),
          Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFFD1D5DB),
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

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
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDropdown(List<User> eligibleUsers) {
    return DropdownButtonFormField<User>(
      isExpanded: true,
      itemHeight: 56,
      value: eligibleUsers.contains(_selectedUserToAdd)
          ? _selectedUserToAdd
          : null,
      selectedItemBuilder: (BuildContext context) {
        return eligibleUsers.map<Widget>((u) {
          final parts = [
            u.firstName,
            u.lastName,
          ].whereType<String>().where((s) => s.isNotEmpty).toList();
          final displayName = parts.isNotEmpty ? parts.join(', ') : u.username;
          return Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: primary.withValues(alpha: 0.08),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
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
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
      ),
      items: eligibleUsers.map((u) {
        final parts = [
          u.firstName,
          u.lastName,
        ].whereType<String>().where((s) => s.isNotEmpty).toList();
        final displayName = parts.isNotEmpty ? parts.join(', ') : u.username;
        return DropdownMenuItem(
          value: u,
          child: Row(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      u.roleName ?? 'User',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }


  Widget _buildCompanyDropdown() {
    return AppTextField(
      readOnly: true,
      controller: _companyAutocompleteController,
      hint: 'Company',
    );
  }
}

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
