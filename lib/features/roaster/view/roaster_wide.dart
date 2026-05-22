import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../asset_group/domain/models/asset_group_model.dart';
import '../../asset_group/presentation/controller/asset_group_provider.dart';
import '../presentation/widgets/add_roster_group_modal.dart';
import '../presentation/controller/roaster_provider.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../core/network/http/api_service.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../user/presentation/controller/user_provider.dart';

// ─── Parameter options ──────────────────────────────────────────────────────
const _kParameters = ['LEVEL', 'BATTERY', 'PRESSURE', 'DEVICE COMMUNICATE FAILED'];

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

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectGroup(AssetGroupModel group) async {
    setState(() {
      _selectedGroup = group;
      _groupUsers = [];
      _userConfigs.clear();
      _selectedRosterIds.clear();
      _loadingUsers = true;
    });

    try {
      // 1. Fetch group detail with users
      final client = ref.read(apiClientProvider);
      final resp = await client.get('/asset-groups/${group.id}');
      final detail = AssetGroupModel.fromJson(resp.data['data']);
      final users = detail.users ?? [];

      // 2. Try to find the latest roster for this group to preview settings
      Map<int, _UserConfig> savedConfigs = {};
      String savedParam = 'LEVEL';
      List<int> rosterIds = [];

      try {
        final rosterResp = await client.get(
          '/roster',
          query: {'description': group.name},
        );
        final rosters = rosterResp.data['data'] as List?;

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
          _groupUsers = users;
          _loadingUsers = false;
          _parameter = savedParam;
          _selectedRosterIds = rosterIds;
          for (final u in users) {
            _userConfigs[u.userId] =
                savedConfigs[u.userId] ?? _UserConfig(userId: u.userId);
          }
        });
      }
    } catch (e) {
      debugPrint('Error selecting group: $e');
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _saveRosters() async {
    final enabledUsers = _userConfigs.values.toList();

    if (enabledUsers.isEmpty) {
      _snack('No users found in this group to configure');
      return;
    }

    setState(() => _savingRoster = true);

    final notifier = ref.read(roasterNotifierProvider.notifier);

    // Create one roster per selected user
    int created = 0;
    for (final cfg in enabledUsers) {
      final user = _groupUsers.firstWhere((u) => u.userId == cfg.userId);
      final data = {
        'description': '${_selectedGroup!.name} – ${user.username}',
        'enabled': 1,
        'parameter_name': _parameter,
        if (_selectedGroup!.companyId != null) 'company_id': _selectedGroup!.companyId,
        'members': [
          {
            'user_id': cfg.userId,
            'email_notif': cfg.email ? 1 : 0,
            'push_notif': cfg.push ? 1 : 0,
            'email_to_phone': cfg.sms ? 1 : 0,
            'enabled': cfg.enabled ? 1 : 0,
            'parameter_name': _parameter,
          },
        ],
      };
      final ok = await notifier.createRoster(data);
      if (ok) created++;
    }

    if (mounted) {
      setState(() => _savingRoster = false);
      _snack('$created roster(s) created successfully');
      // Reset selection
      setState(() {
        _selectedGroup = null;
        _groupUsers.clear();
        _userConfigs.clear();
        _selectedRosterIds.clear();
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
                  AppTableHeaderCell('ACTION', width: 80),
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
              child: Text(
                group.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF141E7A)
                      : const Color(0xFF1F2937),
                ),
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
              width: 80,
              child: Center(
                child: Container(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Right panel: per-user notification toggles ────────────────────────────
  Widget _buildUserConfigPanel() {
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
                      Text(
                        _selectedGroup!.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure notifications per user',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedRosterIds.isNotEmpty) ...[
                  IconButton(
                    onPressed: _deleteSelectedRosters,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.all(8),
                    ),
                    tooltip: 'Delete Configuration',
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () => setState(() {
                    _selectedGroup = null;
                    _groupUsers.clear();
                    _userConfigs.clear();
                    _selectedRosterIds.clear();
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

          // Parameter + Template row
          // Parameter row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: _buildPanelField(
                    label: 'PARAMETER',
                    child: AppDropdown<String>(
                      value: _parameter,
                      items: _kParameters,
                      hint: 'Select Parameter',
                      itemLabel: (p) => p,
                      onChanged: (v) {
                        if (v != null) setState(() => _parameter = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'USER',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _headerCell('EMAIL'),
                _headerCell('PUSH'),
                _headerCell('SMS'),
              ],
            ),
          ),

          const Divider(height: 1),

          // User list
          Expanded(
            child: _loadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _groupUsers.isEmpty
                ? Center(
                    child: Text(
                      'No users in this group',
                      style: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _groupUsers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 24, endIndent: 24),
                    itemBuilder: (_, i) => _buildUserRow(_groupUsers[i]),
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
                        'CREATE ROSTERS',
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

  Widget _buildPanelField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
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
}

// ─── Per-user toggle state ──────────────────────────────────────────────────
class _UserConfig {
  final int userId;
  final bool email;
  final bool push;
  final bool sms;
  final bool enabled;

  const _UserConfig({
    required this.userId,
    this.email = false,
    this.push = false,
    this.sms = false,
    this.enabled = true,
  });

  _UserConfig copyWith({bool? email, bool? push, bool? sms, bool? enabled}) {
    return _UserConfig(
      userId: userId,
      email: email ?? this.email,
      push: push ?? this.push,
      sms: sms ?? this.sms,
      enabled: enabled ?? this.enabled,
    );
  }
}
