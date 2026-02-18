import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/PlantTankDropdownSelector.dart';
import '../../../user/presentation/model/user_model.dart';
import '../controller/group_provider.dart';
import '../model/group_model.dart';

class AddGroupModal extends ConsumerStatefulWidget {
  final Group? group;

  const AddGroupModal({super.key, this.group});

  @override
  ConsumerState<AddGroupModal> createState() => _AddGroupModalState();
}

class _AddGroupModalState extends ConsumerState<AddGroupModal> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<PlantTankAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      // We don't have full name/names in IDs only,
      // but PlantTankDropdownSelector will load them by ID if missing
      _assignments = widget.group!.assignedPlants.map((plantId) {
        final plantTanks = widget.group!.assignedTanks.toList();
        // Note: In current simple model, we store all plant IDs and all tank IDs
        // separately at group level.
        // Ideally we'd store structured assignments.
        // For now, let's treat it as "any tank in some plant"
        return PlantTankAssignment(
          plantId: plantId,
          plantName: 'Plant $plantId',
          allTanks: false,
          tankIds: plantTanks,
        );
      }).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

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
              name: _nameController.text,
              description: _descriptionController.text,
              assignedPlants: plantIds,
              assignedTanks: tankIds.toList(),
            ),
          );
    } else {
      success = await ref
          .read(groupProvider.notifier)
          .updateGroup(widget.group!.id, {
            'name': _nameController.text,
            'description': _descriptionController.text,
            'assigned_plants': plantIds,
            'assigned_tanks': tankIds.toList(),
          });
    }

    if (success && mounted) {
      Navigator.pop(context);
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
        width: 650,
        constraints: const BoxConstraints(maxHeight: 800),
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
                          'Define plant and tank permissions for this group.',
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
                      'GROUP NAME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _nameController,
                      hint: 'Enter group name (e.g., Coimbatore Maintenance)',
                    ),
                    const SizedBox(height: 20),
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
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
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
                      'Users in this group will be able to view and manage these plants and tanks.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    PlantTankDropdownSelector(
                      initialAssignments: _assignments,
                      onChanged: (newAssignments) {
                        _assignments = newAssignments;
                      },
                    ),
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
