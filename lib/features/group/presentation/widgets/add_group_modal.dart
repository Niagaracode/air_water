import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
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
    final plantIds = _assignments.map((a) => a.plantId).toList();

    await _loadUsersForRole(role.id, role.name, plantIds);
  }

  Future<void> _loadUsersForRole(
    int roleId,
    String roleName, [
    List<int>? excludePlantIds,
  ]) async {
    setState(() {
      _isLoadingUsers = true;
      _roleUsers = [];
    });
    try {
      final repository = ref.read(userRepositoryProvider);
      final response = await repository.searchUsers(
        roleId: roleId,
        excludePlantIds: excludePlantIds,
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
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group == null
                              ? 'CREATE ACCESS GROUP'
                              : 'EDIT ACCESS GROUP',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Assign a role and select users for this access group.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
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
                    const Text(
                      'SELECT ROLE (GROUP NAME)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoadingRoles
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedRoleId,
                            decoration: InputDecoration(
                              hintText: 'Select a role',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            items: _roles.map((role) {
                              return DropdownMenuItem(
                                value: role.id,
                                child: Text(role.name),
                              );
                            }).toList(),
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

                    const Text(
                      'PLANT & TANK ACCESS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'First select the plants these users will have access to.',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
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
                      Row(
                        children: [
                          const Text(
                            'ASSIGN USERS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoadingUsers)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50.withOpacity(0.5),
                        ),
                        child: _roleUsers.isEmpty && !_isLoadingUsers
                            ? const Center(
                                child: Text('No users found for this role'),
                              )
                            : ListView.builder(
                                itemCount: _roleUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _roleUsers[index];
                                  final isSelected = _selectedUserIds.contains(
                                    user.userId,
                                  );
                                  return CheckboxListTile(
                                    title: Text(user.fullName),
                                    subtitle: Text(
                                      user.username,
                                      style: const TextStyle(fontSize: 12),
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
                                    activeColor: primary,
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: state.isProcessing ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
