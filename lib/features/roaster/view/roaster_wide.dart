import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../asset_group/domain/models/asset_group_model.dart';
import '../../asset_group/presentation/controller/asset_group_provider.dart';
import '../presentation/widgets/add_roster_group_modal.dart';
import '../presentation/controller/roaster_provider.dart';
import '../../../core/network/http/api_service.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../user/presentation/controller/user_provider.dart';
import '../../user/presentation/model/user_model.dart';
import '../../message_template/presentation/controller/message_template_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';



class RoasterWide extends ConsumerStatefulWidget {
  const RoasterWide({super.key});

  @override
  ConsumerState<RoasterWide> createState() => _RoasterWideState();
}

class _RoasterWideState extends ConsumerState<RoasterWide> {
  AssetGroupModel? _selectedGroup;
  List<AssetGroupUser> _groupUsers = [];
  bool _loadingUsers = false;

  // Per-user notification config (userId → state)
  final Map<int, _UserConfig> _userConfigs = {};

  // Track the roster IDs associated with this group to support deletion
  List<int> _selectedRosterIds = [];

  // Shared parameter for this group session
  String _parameter = 'LEVEL';
  bool _savingRoster = false;

  User? _selectedUserToAdd;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  CompanyAutocomplete? _selectedCompany;
  List<CompanyAutocomplete> _companies = [];
  bool _isLoadingCompanies = false;
  List<User> _companyUsers = [];
  bool _isLoadingUsers = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(rosterGroupProvider.notifier).loadGroups();
      ref.read(messageTemplateProvider.notifier).loadTemplates();
    });
  }

  Future<void> _selectGroup(AssetGroupModel group) async {
    setState(() {
      _selectedGroup = group;
      _groupUsers = [];
      _userConfigs.clear();
      _selectedRosterIds.clear();
      _loadingUsers = true;
      _selectedUserToAdd = null;
    });

    try {
      // 1. Fetch group detail
      final client = ref.read(apiClientProvider);
      final resp = await client.get('/asset-groups/${group.id}');
      final detail = AssetGroupModel.fromJson(resp.data['data']);

      // 2. Try to find the latest roster for this group to preview settings
      Map<int, _UserConfig> savedConfigs = {};
      List<AssetGroupUser> loadedUsers = [];
      String savedParam = 'LEVEL';
      List<int> rosterIds = [];
      List? rosters;

      try {
        var rosterResp = await client.get(
          '/roster',
          query: {
            'roster_group_id': group.id,
            'limit': 100,
          },
        );
        rosters = rosterResp.data['data'] as List?;

        if (rosters == null || rosters.isEmpty) {
          rosterResp = await client.get(
            '/roster',
            query: {
              'description': group.name,
              'limit': 100,
            },
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

                    loadedUsers.add(AssetGroupUser(
                      userId: uid,
                      username: m['username'] ?? '',
                      firstName: m['first_name'],
                      lastName: m['last_name'],
                      roleName: m['role_name'],
                    ));
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
          _selectedGroup = detail;
          _nameController.text = detail.name;
          _descController.text = detail.description;
          _selectedCompany = detail.companyId != null
              ? CompanyAutocomplete(
                  id: detail.companyId!,
                  name: detail.companyName ?? '',
                )
              : null;
          
          _userConfigs.clear();
          for (final gu in loadedUsers) {
            _userConfigs[gu.userId] = savedConfigs[gu.userId]!;
          }
          _groupUsers = loadedUsers;
          
          _loadingUsers = false;
          _parameter = (savedParam != 'LEVEL') ? savedParam : (detail.parameterName ?? 'LEVEL');
          _selectedRosterIds = rosterIds;
          _selectedUserToAdd = null;
        });

        final currentUser = ref.read(userProvider).currentUser;
        final companyId = _selectedCompany?.id ?? currentUser?.companyId;
        if (companyId != null) {
          _loadCompanyUsers(companyId);
        }
        if (currentUser?.roleId == 1) {
          _loadCompanies();
        }
      }
    } catch (e) {
      debugPrint('Error selecting group: $e');
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _saveRosters() async {
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      _snack('Please enter Group Name');
      return;
    }

    final currentUser = ref.read(userProvider).currentUser;
    if (currentUser == null) return;

    if (currentUser.roleId == 1 && _selectedCompany == null) {
      _snack('Please select a Company');
      return;
    }

    setState(() => _savingRoster = true);

    int? siteId;
    if (_selectedGroup != null) {
      for (final criterion in _selectedGroup!.criteria) {
        if (criterion.parameter == 'site_id') {
          siteId = int.tryParse(criterion.value);
          break;
        }
      }
    }

    // 1. Prepare and save the updated group details
    final updatedGroup = AssetGroupModel(
      id: _selectedGroup!.id,
      name: groupName,
      description: _descController.text.trim(),
      displayInTree: _selectedGroup!.displayInTree,
      status: _selectedGroup!.status,
      domain: _selectedGroup!.domain,
      criteria: _selectedGroup!.criteria,
      companyId: _selectedCompany?.id ?? currentUser.companyId,
      companyName: _selectedCompany?.name,
      siteId: _selectedGroup!.siteId,
      parameterName: _selectedGroup!.parameterName,
      tankId: _selectedGroup!.tankId,
    );

    final savedId = await ref
        .read(assetGroupProvider.notifier)
        .saveGroupAndGetId(updatedGroup, users: _groupUsers);

    if (savedId == null) {
      if (mounted) {
        setState(() => _savingRoster = false);
        final error = ref.read(assetGroupProvider).error;
        _snack('Failed to save group: ${error ?? "Unknown error"}');
      }
      return;
    }

    // 2. Delete old rosters
    final rosterNotifier = ref.read(roasterNotifierProvider.notifier);
    for (final id in _selectedRosterIds) {
      await rosterNotifier.deleteRoaster(id);
    }

    // 3. Create new rosters for all assigned users
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
        if (cfg.messageTemplateId != null) 'message_template_id': cfg.messageTemplateId,
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
            if (cfg.messageTemplateId != null) 'message_template_id': cfg.messageTemplateId,
          },
        ],
      };
      final ok = await rosterNotifier.createRoster(data);
      if (ok) created++;
    }

    // Refresh groups
    ref.read(rosterGroupProvider.notifier).loadGroups();

    if (mounted) {
      setState(() => _savingRoster = false);
      _snack('Roster group and $created user configuration(s) updated successfully');
      
      // Reset selection
      setState(() {
        _selectedGroup = null;
        _groupUsers.clear();
        _userConfigs.clear();
        _selectedRosterIds.clear();
        _selectedUserToAdd = null;
      });
    }
  }

  Future<void> _deleteSelectedRosters() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Roster Configuration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete the roster configuration for "${_selectedGroup!.name}"? This will delete all active rosters associated with this group.',
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _savingRoster = true);
      final notifier = ref.read(roasterNotifierProvider.notifier);
      int deletedCount = 0;
      for (final id in _selectedRosterIds) {
        final ok = await notifier.deleteRoaster(id);
        if (ok) deletedCount++;
      }

      if (mounted) {
        setState(() {
          _savingRoster = false;
          _selectedGroup = null;
          _groupUsers.clear();
          _userConfigs.clear();
          _selectedRosterIds.clear();
          _selectedUserToAdd = null;
        });
        _snack(
          'Roster configuration deleted successfully ($deletedCount roster(s) removed)',
        );
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDeleteGroup(AssetGroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Roster Group',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone and will delete the group.',
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && group.id != null) {
      final success = await ref.read(assetGroupProvider.notifier).deleteGroup(group.id!);
      if (success) {
        ref.read(rosterGroupProvider.notifier).loadGroups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Roster group deleted successfully')),
          );
          if (_selectedGroup?.id == group.id) {
            setState(() {
              _selectedGroup = null;
              _groupUsers.clear();
              _userConfigs.clear();
              _selectedRosterIds.clear();
              _selectedUserToAdd = null;
            });
          }
        }
      } else {
        if (mounted) {
          final error = ref.read(assetGroupProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: ${error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(rosterGroupProvider);
    final userState = ref.watch(userProvider);
    final isSuperAdmin = userState.currentUser?.roleId == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ── Left: Group list (Table Format) ────────────────────────────────
          Expanded(
            flex: _selectedGroup != null ? 2 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageHeader(),
                Expanded(
                  child: groupState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : groupState.error != null
                      ? Center(child: Text(groupState.error!))
                      : _buildGroupTable(
                          groupState.groups
                              .where((g) => g.status == 1)
                              .toList(),
                          isSuperAdmin,
                        ),
                ),
              ],
            ),
          ),

          // ── Right: User config panel ──────────────────────────────────────
          if (_selectedGroup != null)
            Expanded(flex: 3, child: _buildUserConfigPanel()),
        ],
      ),
    );
  }

  // ─── Page header ──────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E7A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Color(0xFF141E7A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ROASTER MANAGEMENT',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select an asset group to configure notifications.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'Dismiss',
                barrierColor: Colors.black.withValues(alpha: 0.5),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) =>
                    const AddRosterGroupModal(),
                transitionBuilder: (context, anim1, anim2, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(anim1),
                    child: child,
                  );
                },
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              'CREATE GROUP',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF141E7A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Table of asset groups ────────────────────────────────────────────────
  Widget _buildGroupTable(List<AssetGroupModel> groups, bool isSuperAdmin) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No asset groups found',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF141E7A),
                // Header is not rounded anymore because it's part of the list
              ),
              child: Row(
                children: [
                  AppTableHeaderCell('SI.NO', width: 60),
                  if (isSuperAdmin) AppTableHeaderCell('COMPANY', flex: 2),
                  AppTableHeaderCell('GROUP NAME', flex: 2),
                  AppTableHeaderCell('DESCRIPTION', flex: 3),
                  AppTableHeaderCell('ACTION', width: 120),
                ],
              ),
            ),
            // Table Body
            Expanded(
              child: ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) =>
                    _buildGroupRow(groups[i], i, isSuperAdmin),
              ),
            ),
            const AppTableBottomCap(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupRow(AssetGroupModel group, int index, bool isSuperAdmin) {
    final isSelected = _selectedGroup?.id == group.id;
    return InkWell(
      onTap: () => _selectGroup(group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF141E7A).withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            left: isSelected
                ? const BorderSide(color: Color(0xFF141E7A), width: 4)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            AppTableCell((index + 1).toString().padLeft(2, '0'), width: 60),
            if (isSuperAdmin)
              AppTableCell(
                group.companyName ?? '-',
                flex: 2,
                color: const Color(0xFF141E7A),
                bold: true,
              ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF141E7A)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  if (group.criteria.any((c) => c.parameter == 'Site Name'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Site: ${group.criteria.firstWhere((c) => c.parameter == 'Site Name').value}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                group.description.isNotEmpty ? group.description : '-',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _confirmDeleteGroup(group),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'Delete Group',
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF141E7A)
                          : const Color(0xFF141E7A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFF141E7A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Right panel: edit roster group & per-user notifications ───────────────
  Widget _buildUserConfigPanel() {
    final isSuperAdmin = ref.watch(userProvider).currentUser?.roleId == 1;

    final eligibleUsers = _companyUsers.where((u) {
      final alreadyAdded = _groupUsers.any((a) => a.userId == u.userId);
      return !alreadyAdded && u.roleId != 1;
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _selectedGroup!.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (_selectedGroup!.criteria.any((c) => c.parameter == 'Site Name')) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _selectedGroup!.criteria.firstWhere((c) => c.parameter == 'Site Name').value,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Edit roster group details and configurations',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () => setState(() {
                    _selectedGroup = null;
                    _groupUsers.clear();
                    _userConfigs.clear();
                    _selectedRosterIds.clear();
                    _selectedUserToAdd = null;
                  }),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GROUP NAME
                  _buildLabel('GROUP NAME*'),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _nameController,
                    hint: 'e.g. Battery Maintenance Group',
                  ),
                  const SizedBox(height: 20),

                  // DESCRIPTION
                  _buildLabel('DESCRIPTION'),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _descController,
                    hint: 'e.g. Roster group for notifications',
                  ),
                  const SizedBox(height: 20),

                  // COMPANY (Super Admin only)
                  if (isSuperAdmin) ...[
                    _buildLabel('COMPANY*'),
                    const SizedBox(height: 8),
                    _buildCompanyDropdown(),
                    const SizedBox(height: 20),
                  ],

                  // ASSIGN USERS
                  _buildLabel('ASSIGN USERS'),
                  const SizedBox(height: 8),

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
                                        _groupUsers.add(AssetGroupUser(
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
                                    },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF141E7A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                            disabledForegroundColor: const Color(0xFF9CA3AF),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
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

                  // Assigned users notification table
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
                              const Icon(
                                Icons.notifications_active_outlined,
                                size: 15,
                                color: Color(0xFF141E7A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'NOTIFICATION SETTINGS',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF141E7A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141E7A)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_groupUsers.length} user${_groupUsers.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF141E7A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          // Table Column headers
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

                          // User rows
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
                ],
              ),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _savingRoster ? null : _saveRosters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
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
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return SizedBox(
      width: 72,
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
      width: 150,
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
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    final displayName = fullName.isNotEmpty ? fullName : user.username;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E7A).withValues(alpha: 0.08),
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
                        color: const Color(0xFF141E7A),
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
          // Email toggle
          _toggle(cfg.email, (v) {
            setState(() => _userConfigs[user.userId] = cfg.copyWith(email: v));
          }),
          // Push toggle
          _toggle(cfg.push, (v) {
            setState(() => _userConfigs[user.userId] = cfg.copyWith(push: v));
          }),
          // SMS toggle
          _toggle(cfg.sms, (v) {
            setState(() => _userConfigs[user.userId] = cfg.copyWith(sms: v));
          }),
          // Message template selector
          Container(
            width: 150,
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
                hint: Text('Select Template', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                icon: const Icon(Icons.arrow_drop_down, size: 16),
                items: [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text('None', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
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
          // Delete action
          SizedBox(
            width: 48,
            child: Center(
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _groupUsers.removeWhere((gu) => gu.userId == user.userId);
                    _userConfigs.remove(user.userId);
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
      width: 72,
      child: Center(
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: const Color(0xFF141E7A),
          activeThumbColor: Colors.white,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE5E7EB),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
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

  Widget _buildUserDropdown(List<User> eligibleUsers) {
    return DropdownButtonFormField<User>(
      isExpanded: true,
      itemHeight: 56,
      value: eligibleUsers.contains(_selectedUserToAdd)
          ? _selectedUserToAdd
          : null,
      selectedItemBuilder: (BuildContext context) {
        return eligibleUsers.map<Widget>((u) {
          final displayName = u.fullName;
          return Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor:
                    const Color(0xFF141E7A).withValues(alpha: 0.08),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141E7A),
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
        final displayName = u.fullName;
        return DropdownMenuItem(
          value: u,
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    const Color(0xFF141E7A).withValues(alpha: 0.08),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141E7A),
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
              const BorderSide(color: Color(0xFF141E7A), width: 1.5),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    if (_isLoadingCompanies) {
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
              'Loading companies…',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<CompanyAutocomplete>(
      isExpanded: true,
      value: _companies.any((c) => c.id == _selectedCompany?.id)
          ? _companies.firstWhere((c) => c.id == _selectedCompany?.id)
          : null,
      hint: Text(
        'Select a company…',
        style:
            GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
      ),
      items: _companies.map((c) {
        return DropdownMenuItem<CompanyAutocomplete>(
          value: c,
          child: Text(
            c.name,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (o) {
        if (o == null) return;
        setState(() {
          _selectedCompany = o;
          _groupUsers.clear();
          _userConfigs.clear();
          _selectedUserToAdd = null;
          _companyUsers = [];
        });
        _loadCompanyUsers(o.id);
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF141E7A), width: 1.5),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
    );
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


}

// ─── Per-user toggle state ──────────────────────────────────────────────────
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
      messageTemplateId: clearTemplate ? null : (messageTemplateId ?? this.messageTemplateId),
    );
  }
}



