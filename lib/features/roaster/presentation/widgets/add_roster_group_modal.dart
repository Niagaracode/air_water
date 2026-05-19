import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Features
import '../../../asset_group/domain/models/asset_group_model.dart';
import '../../../asset_group/presentation/controller/asset_group_provider.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';

// Shared
import '../../../../shared/widgets/app_text_field.dart';

class AddRosterGroupModal extends ConsumerStatefulWidget {
  const AddRosterGroupModal({super.key});

  @override
  ConsumerState<AddRosterGroupModal> createState() => _AddRosterGroupModalState();
}

class _AddRosterGroupModalState extends ConsumerState<AddRosterGroupModal> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _companyAutocompleteController = TextEditingController();
  final _companyFocusNode = FocusNode();
  
  bool _isActive = true;
  CompanyAutocomplete? _selectedCompany;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(userProvider).currentUser;
      if (currentUser != null && currentUser.roleId != 1) {
        setState(() {
          _selectedCompany = CompanyAutocomplete(
            id: currentUser.companyId!,
            name: currentUser.companyName!,
          );
          _companyAutocompleteController.text = currentUser.companyName!;
        });
      }
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

    final isSuperAdmin = currentUser.roleId == 1;
    if (isSuperAdmin && _selectedCompany == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Company')),
      );
      return;
    }

    final groupDesc = _descController.text.trim();

    final newGroup = AssetGroupModel(
      name: groupName,
      description: groupDesc,
      displayInTree: _isActive,
      status: _isActive ? 1 : 0,
      domain: 'ROSTER',
      criteria: const [],
      companyId: _selectedCompany?.id ?? currentUser.companyId,
    );

    final success = await ref.read(assetGroupProvider.notifier).saveGroup(newGroup);

    if (!mounted) return;

    if (success) {
      ref.read(rosterGroupProvider.notifier).loadGroups();
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Roster group created successfully')),
      );
    } else {
      final error = ref.read(assetGroupProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to create group: ${error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assetGroupProvider);
    final currentUser = ref.watch(userProvider).currentUser;
    final isSuperAdmin = currentUser?.roleId == 1;

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
                child: SingleChildScrollView(
                  child: Padding(
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
                                  'Create Roster Group',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Define basic roster group information.',
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
                        const SizedBox(height: 32),
                        
                        // Group Name
                        _buildLabelField(
                          'GROUP NAME*',
                          AppTextField(
                            controller: _nameController,
                            hint: 'e.g. Battery Maintenance Group',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Description
                        _buildLabelField(
                          'DESCRIPTION',
                          AppTextField(
                            controller: _descController,
                            hint: 'e.g. Roster group for notifications',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Company Autocomplete (Super Admin Only)
                        if (isSuperAdmin) ...[
                          _buildLabelField(
                            'COMPANY*',
                            _buildCompanyAutocomplete(),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Status Toggle
                        _buildStatusToggle(),
                        const SizedBox(height: 48),

                        // Create Button
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
                                    'CREATE GROUP',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
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
                  'STATUS',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF141E7A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toggle group active/inactive status.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeTrackColor: const Color(0xFF141E7A),
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<CompanyAutocomplete>(
        focusNode: _companyFocusNode,
        textEditingController: _companyAutocompleteController,
        optionsBuilder: (TextEditingValue v) => v.text.isEmpty
            ? <CompanyAutocomplete>[]
            : ref.read(userProvider.notifier).searchCompanies(v.text),
        displayStringForOption: (o) => o.name,
        fieldViewBuilder: (context, controller, focus, onSubmitted) =>
            AppTextField(
              controller: controller,
              focusNode: focus,
              hint: 'Search Company...',
            ),
        onSelected: (o) => setState(() => _selectedCompany = o),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: constraints.maxWidth,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    hoverColor: const Color(0xFFF3F4F6),
                    title: Text(
                      option.name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
