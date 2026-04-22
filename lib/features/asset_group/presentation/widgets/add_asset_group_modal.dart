import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/asset_group_model.dart';
import '../controller/asset_group_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../view/asset_group_edit_page.dart';

class AddAssetGroupModal extends ConsumerStatefulWidget {
  final AssetGroupModel? initialGroup;
  const AddAssetGroupModal({super.key, this.initialGroup});

  @override
  ConsumerState<AddAssetGroupModal> createState() => _AddAssetGroupModalState();
}

class _AddAssetGroupModalState extends ConsumerState<AddAssetGroupModal> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _displayInTree = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null) {
      _nameController.text = widget.initialGroup!.name;
      _descriptionController.text = widget.initialGroup!.description;
      _displayInTree = widget.initialGroup!.displayInTree;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_nameController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter Group Name')),
      );
      return;
    }

    final newGroup = AssetGroupModel(
      id: widget.initialGroup?.id,
      name: _nameController.text,
      description: _descriptionController.text,
      displayInTree: _displayInTree,
      criteria: widget.initialGroup?.criteria ?? [],
      users: widget.initialGroup?.users,
    );

    final success = await ref.read(assetGroupProvider.notifier).saveGroup(newGroup);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      
      // If creating a NEW group, we might want to redirect to the edit page to define criteria
      if (widget.initialGroup == null) {
        // Find the newly created group (highest ID or by name) OR handle in provider to return the created object
        // For now, reload is handled by saveGroup. We can navigate to edit page if needed.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully. Edit it to define criteria.')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
      }
    } else {
      final error = ref.read(assetGroupProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Action failed: ${error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: SizedBox(
          width: 500,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.initialGroup != null ? 'Edit Group' : 'Create Group',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Define basic group information.',
                                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          _buildLabelField(
                            'GROUP NAME',
                            AppTextField(
                              controller: _nameController,
                              hint: 'e.g. All Battery Tanks',
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildLabelField(
                            'DETAILED DESCRIPTION',
                            AppTextField(
                              controller: _descriptionController,
                              hint: 'e.g. This group includes all tanks categorized under battery maintenance...',
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildStatusToggle(),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: state.isProcessing ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF141E7A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: state.isProcessing
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      widget.initialGroup != null ? 'UPDATE GROUP' : 'CREATE GROUP',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                            ),
                          ),
                          if (widget.initialGroup != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AssetGroupEditPage(group: widget.initialGroup),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.settings_suggest_outlined),
                                label: const Text('EDIT GROUP CRITERIA & USERS'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  side: const BorderSide(color: Color(0xFF141E7A)),
                                  foregroundColor: const Color(0xFF141E7A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            color: const Color(0xFF141E7A),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        field,
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  'DISPLAY IN TREE',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF141E7A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Show this group in navigation.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Switch(
            value: _displayInTree,
            onChanged: (v) => setState(() => _displayInTree = v),
            activeColor: const Color(0xFF141E7A),
          ),
        ],
      ),
    );
  }
}
