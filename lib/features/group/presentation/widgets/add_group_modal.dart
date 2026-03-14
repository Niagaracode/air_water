import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/PlantTankDropdownSelector.dart';
import '../../../user/presentation/model/user_model.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../controller/group_provider.dart';
import '../model/group_model.dart';

class AddGroupModal extends ConsumerStatefulWidget {
  final Group? group;

  const AddGroupModal({super.key, this.group});

  @override
  ConsumerState<AddGroupModal> createState() => _AddGroupModalState();
}

class _AddGroupModalState extends ConsumerState<AddGroupModal> {
  final _descriptionController = TextEditingController();
  List<PlantTankAssignment> _assignments = [];

  List<Role> _roles = [];
  int? _selectedRoleId;
  List<User> _roleUsers = [];
  final Set<int> _selectedUserIds = {};
  bool _isLoadingRoles = false;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingRoles = true);
    try {
      final roles = await ref.read(userProvider.notifier).getRoles();
      setState(() {
        _roles = roles;
        _isLoadingRoles = false;
      });

      if (widget.group != null) {
        _descriptionController.text = widget.group!.description ?? '';

        // Load existing user assignments
        final groupUsers = await ref
            .read(groupProvider.notifier)
            .getGroupUsers(widget.group!.id);
        setState(() {
          _selectedUserIds.addAll(groupUsers.map((u) => u.userId));
        });

        // Initialize assignments
        _assignments = widget.group!.assignedPlants.map((plantId) {
          final plantTanks = widget.group!.assignedTanks.toList();
          return PlantTankAssignment(
            plantId: plantId,
            plantName: 'Plant $plantId',
            allTanks: false,
            tankIds: plantTanks,
          );
        }).toList();

        // Find existing role if name matches
        final role = _roles
            .where((r) => r.name == widget.group!.name)
            .firstOrNull;
        if (role != null) {
          _selectedRoleId = role.id;
        }
      }

      // Initial user load based on current state
      await _refreshUsers();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoles = false);
      }
    }
  }

  Future<void> _refreshUsers() async {
    if (_selectedRoleId == null) {
      setState(() {
        _roleUsers = [];
        _isLoadingUsers = false;
      });
      return;
    }

    final role = _roles.firstWhere((r) => r.id == _selectedRoleId);
    
    // Construct structured assignments for precise exclusion
    final List<Map<String, dynamic>> excludeAssignments = _assignments.map((a) {
      return {
        'plant_id': a.plantId,
        if (a.tankIds != null && a.tankIds!.isNotEmpty) 'tank_ids': a.tankIds,
        'all_tanks': a.allTanks,
      };
    }).toList();

    await _loadUsersForRole(role.id, role.name, excludeAssignments);
  }

  Future<void> _loadUsersForRole(
    int roleId,
    String roleName, [
    List<Map<String, dynamic>>? excludeAssignments,
  ]) async {
    setState(() {
      _isLoadingUsers = true;
      _roleUsers = [];
    });
    try {
      final repository = ref.read(userRepositoryProvider);
      final response = await repository.searchUsers(
        roleId: roleId,
        excludeAssignments: excludeAssignments,
        groupName: roleName,
        limit: 100,
      );
      setState(() {
        _roleUsers = response.data;
        _isLoadingUsers = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }

    final selectedRole = _roles.firstWhere((r) => r.id == _selectedRoleId);
    final plantIds = _assignments.map((a) => a.plantId).toList();
    final tankIds = <int>{};
    for (var a in _assignments) {
      if (a.tankIds != null) tankIds.addAll(a.tankIds!);
    }

    bool success;
    if (widget.group == null) {
      success = await ref
          .read(groupProvider.notifier)
          .createGroup(
            GroupCreateRequest(
              name: selectedRole.name,
              description: _descriptionController.text,
              assignedPlants: plantIds,
              assignedTanks: tankIds.toList(),
              userIds: _selectedUserIds.toList(),
            ),
          );
    } else {
      success = await ref
          .read(groupProvider.notifier)
          .updateGroup(widget.group!.id, {
            'name': selectedRole.name,
            'description': _descriptionController.text,
            'assigned_plants': plantIds,
            'assigned_tanks': tankIds.toList(),
            'user_ids': _selectedUserIds.toList(),
          });
    }

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.group == null
                ? 'Group created successfully'
                : 'Group updated successfully',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 850),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.group_add_rounded,
                      color: const Color(0xFF475569),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group == null
                              ? 'CREATE ACCESS GROUP'
                              : 'EDIT ACCESS GROUP',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure role permissions and user assignments for this group.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4B5563),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                    hoverColor: const Color(0xFFF3F4F6),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 18,
                            color: const Color(0xFF475569),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SELECT ROLE (GROUP NAME)',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingRoles
                        ? const Center(child: CircularProgressIndicator())
                        : AppDropdown<int>(
                            value: _selectedRoleId,
                            hint: 'Select a role',
                            items: _roles.map((r) => r.id).toList(),
                            itemLabel: (id) =>
                                _roles.firstWhere((r) => r.id == id).name,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedRoleId = val;
                                  _selectedUserIds.clear();
                                });
                                _refreshUsers();
                              }
                            },
                          ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.factory_rounded,
                            size: 18,
                            color: const Color(0xFF475569),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PLANT & TANK ACCESS',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'First select the plants these users will have access to.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PlantTankDropdownSelector(
                      initialAssignments: _assignments,
                      onChanged: (newAssignments) {
                        setState(() {
                          _assignments = newAssignments;
                        });
                        _refreshUsers();
                      },
                    ),
                    const SizedBox(height: 24),

                    if (_selectedRoleId != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_add_rounded,
                              size: 18,
                              color: const Color(0xFF475569),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ASSIGN USERS',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const Spacer(),
                            if (_isLoadingUsers)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF9FAFB),
                        ),
                        child: _roleUsers.isEmpty && !_isLoadingUsers
                            ? Center(
                                child: Text(
                                  'No users found for this role',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _roleUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _roleUsers[index];
                                  final isSelected = _selectedUserIds.contains(
                                    user.userId,
                                  );
                                  return CheckboxListTile(
                                    title: Text(
                                      user.fullName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    subtitle: Text(
                                      user.username,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                    value: isSelected,
                                    dense: true,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedUserIds.add(user.userId);
                                        } else {
                                          _selectedUserIds.remove(user.userId);
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF475569),
                                    checkColor: Colors.white,
                                    checkboxShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.description_rounded,
                            size: 18,
                            color: const Color(0xFF475569),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'DESCRIPTION',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _descriptionController,
                      hint: 'Enter group description...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: state.isProcessing ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF141E7A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: state.isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.group == null ? 'CREATE' : 'SAVE CHANGES',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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
}
