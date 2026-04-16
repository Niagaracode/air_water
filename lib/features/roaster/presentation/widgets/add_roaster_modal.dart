import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/roaster_provider.dart';
import '../model/roaster_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';
import '../../../message_template/presentation/controller/message_template_provider.dart';
import '../../../message_template/presentation/model/message_template_model.dart';
import '../../../setting/presentation/controller/setting_provider.dart';
import '../../../../shared/widgets/app_multi_select_dropdown.dart';

class AddRosterModal extends ConsumerStatefulWidget {
  final Roster? roster;
  final List<RosterMember>? templateMembers;
  const AddRosterModal({super.key, this.roster, this.templateMembers});

  @override
  ConsumerState<AddRosterModal> createState() => _AddRosterModalState();
}

class _AddRosterModalState extends ConsumerState<AddRosterModal> {
  final _descriptionController = TextEditingController();
  bool _enabled = true;
  bool _isLoadingData = false;

  List<Role> _roles = [];
  List<MessageTemplate> _templates = [];
  List<Map<String, dynamic>> _allowedTemplates = [];

  List<Role> _selectedRoles = [];
  List<User> _filteredUsersList = []; // Users filtered by selected roles
  List<User> _selectedUsers = [];
  MessageTemplate? _selectedTemplate;
  String _selectedParameter = 'LEVEL';
  bool _isLoadingUsers = false;
  int _loadGeneration = 0; // Guards against stale async results

  final List<String> _parameters = [
    'LEVEL',
    'BATTERY',
    'PRESSURE',
    'TEMPERATURE',
    'FLOW',
    'Cal Tank',
    'Cal Kilo Liter',
    'sensor',
    'setbar',
    'setcalbar',
    'mfactor',
    'Data Interval',
    'Chart Data',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.roster != null) {
      _descriptionController.text = widget.roster!.description;
      _enabled = widget.roster!.enabled == 1;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    try {
      final userNotifier = ref.read(userProvider.notifier);
      final templateRepo = ref.read(messageTemplateRepositoryProvider);
      final settingRepo = ref.read(settingRepositoryProvider);

      final roles = await userNotifier.getRoles();
      final templates = await templateRepo.getActiveTemplates();
      final allowed = await settingRepo.getTemplatesByParameter(
        _selectedParameter,
      );

      if (mounted) {
        setState(() {
          _roles = roles;
          _templates = templates;
          _allowedTemplates = allowed;

          if (widget.templateMembers != null) {
            final roleIds = widget.templateMembers!
                .map((m) => m.roleId)
                .toSet();
            _selectedRoles = _roles
                .where((r) => roleIds.contains(r.id))
                .toList();

            final templateId = widget.templateMembers!.first.messageTemplateId;
            _selectedTemplate = _templates
                .where((t) => t.id == templateId)
                .firstOrNull;
          }
        });
      }

      // Load members for pre-selected roles (edit mode)
      if (_selectedRoles.isNotEmpty) {
        await _loadUsersByRoles(_selectedRoles);
        // Restore pre-selected users from templateMembers
        if (widget.templateMembers != null && mounted) {
          final userIds = widget.templateMembers!
              .where((m) => m.userId != null)
              .map((m) => m.userId)
              .toSet();
          setState(() {
            _selectedUsers = _filteredUsersList
                .where((u) => userIds.contains(u.userId))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  /// Fetches users for each selected role from the API and merges results.
  /// Uses a generation counter to ignore results from stale (superseded) requests.
  Future<void> _loadUsersByRoles(List<Role> roles) async {
    final myGeneration = ++_loadGeneration;
    if (roles.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredUsersList = [];
          _selectedUsers = [];
          _isLoadingUsers = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _isLoadingUsers = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final List<User> merged = [];
      final seenIds = <int>{};
      for (final role in roles) {
        // Abort if a newer request has been triggered
        if (myGeneration != _loadGeneration) return;
        final users = await userRepo.getUsers(roleId: role.id);
        for (final u in users) {
          if (seenIds.add(u.userId)) {
            merged.add(u);
          }
        }
      }
      // Only apply if this is still the latest request
      if (myGeneration == _loadGeneration && mounted) {
        setState(() {
          _filteredUsersList = merged;
          // Remove selected users that no longer belong to any of the new roles
          final validIds = merged.map((u) => u.userId).toSet();
          _selectedUsers = _selectedUsers
              .where((u) => validIds.contains(u.userId))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading users by roles: $e');
    } finally {
      if (myGeneration == _loadGeneration && mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  // _filteredUsersList is now populated by _loadUsersByRoles()
  // and always contains only users matching the selected roles.

  Future<void> _updateAllowedTemplates(String parameter) async {
    try {
      final settingRepo = ref.read(settingRepositoryProvider);
      final allowed = await settingRepo.getTemplatesByParameter(parameter);

      if (mounted) {
        setState(() {
          _allowedTemplates = allowed;
          if (_selectedTemplate != null &&
              !allowed.any((t) => t['id'] == _selectedTemplate!.id)) {
            _selectedTemplate = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating allowed templates: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    final Map<String, dynamic> data = {
      'description': _descriptionController.text.trim(),
      'enabled': _enabled ? 1 : 0,
    };

    if (_selectedRoles.isNotEmpty) {
      data['role_ids'] = _selectedRoles.map((role) => role.id).toList();
    }
    data['parameter_name'] = _selectedParameter;
    data['message_template_id'] = _selectedTemplate?.id;

    if (_selectedUsers.isNotEmpty) {
      data['members'] = _selectedUsers.map((user) => {
        'user_id': user.userId,
        'role_id': user.roleId,
        'parameter_name': _selectedParameter,
        'message_template_id': _selectedTemplate?.id,
        'enabled': 1,
      }).toList();
    }

    bool success;
    if (widget.roster != null) {
      success = await ref
          .read(roasterNotifierProvider.notifier)
          .updateRoster(widget.roster!.id, data);
    } else {
      success = await ref
          .read(roasterNotifierProvider.notifier)
          .createRoster(data);
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Roster ${widget.roster != null ? 'updated' : 'created'} successfully',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.roster != null
                                      ? 'Edit Roster'
                                      : 'Create New Roster',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Define a new notification team with roles.',
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
                            icon: const Icon(Icons.close_rounded),
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
                      const SizedBox(height: 32),
                      _buildInfoBar(),
                      const SizedBox(height: 32),
                      if (_isLoadingData)
                        const Center(child: LinearProgressIndicator())
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('DESCRIPTION'),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _descriptionController,
                                  hint: 'e.g. Battery Maintenance Team',
                                ),
                                const SizedBox(height: 24),
                                _buildLabel('SELECT ROLES'),
                                const SizedBox(height: 12),
                                AppMultiSelectDropdown<Role>(
                                  selectedItems: _selectedRoles,
                                  items: _roles,
                                  hint: 'Select Multiple Roles',
                                  itemLabel: (r) => r.name,
                                  onChanged: (list) {
                                    setState(() => _selectedRoles = list);
                                    // Fetch users for the newly selected roles from API
                                    _loadUsersByRoles(list);
                                  },
                                ),
                                // Show loading indicator while fetching members
                                if (_isLoadingUsers) ...
                                  [
                                    const SizedBox(height: 24),
                                    _buildLabel('SELECT MEMBERS'),
                                    const SizedBox(height: 12),
                                    const LinearProgressIndicator(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Loading members for selected role(s)...',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ]
                                // Show members dropdown only when members exist
                                else if (_filteredUsersList.isNotEmpty) ...
                                  [
                                    const SizedBox(height: 24),
                                    _buildLabel('SELECT MEMBERS'),
                                    const SizedBox(height: 12),
                                    AppMultiSelectDropdown<User>(
                                      selectedItems: _selectedUsers,
                                      items: _filteredUsersList,
                                      hint: 'Select Members',
                                      itemLabel: (u) {
                                        final name = '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();
                                        final display = name.isNotEmpty ? name : u.username;
                                        return '$display (${u.roleName ?? ''})';
                                      },
                                      onChanged: (list) =>
                                          setState(() => _selectedUsers = list),
                                    ),
                                  ],
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel('PARAMETER'),
                                          const SizedBox(height: 12),
                                          AppDropdown<String>(
                                            value: _selectedParameter,
                                            items: _parameters,
                                            hint: 'Select Parameter',
                                            itemLabel: (p) => p,
                                            onChanged: (v) {
                                              if (v != null) {
                                                setState(
                                                  () => _selectedParameter = v,
                                                );
                                                _updateAllowedTemplates(v);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel('MESSAGE TEMPLATE'),
                                          const SizedBox(height: 12),
                                          AppDropdown<MessageTemplate>(
                                            value: _selectedTemplate,
                                            items: _templates
                                                .where(
                                                  (t) => _allowedTemplates.any(
                                                    (at) => at['id'] == t.id,
                                                  ),
                                                )
                                                .toList(),
                                            hint: 'Select Template',
                                            itemLabel: (t) => t.name,
                                            onChanged: (v) => setState(
                                              () => _selectedTemplate = v,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                _buildStatusToggle(),
                                const SizedBox(height: 48),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF141E7A),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            widget.roster != null
                                ? 'UPDATE ROSTER'
                                : 'CREATE ROSTER',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF333333),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF92400E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Specify the details of the team to begin adding contacts and configuring notification rules later.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() {
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
                  'INITIAL STATUS',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  'The team will be active immediately.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF141E7A),
          ),
        ],
      ),
    );
  }
}
