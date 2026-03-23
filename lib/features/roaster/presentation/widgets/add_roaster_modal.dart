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
import '../../../rule/presentation/controller/rule_provider.dart';
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
  MessageTemplate? _selectedTemplate;
  String _selectedParameter = 'LEVEL';

  final List<String> _parameters = [
    'LEVEL',
    'BATTERY',
    'PRESSURE',
    'TEMPERATURE',
    'FLOW',
    'OTHER'
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
      final ruleRepo = ref.read(ruleRepositoryProvider);

      final roles = await userNotifier.getRoles();
      final templates = await templateRepo.getActiveTemplates();
      final allowed = await ruleRepo.getTemplatesByParameter(_selectedParameter);

      if (mounted) {
        setState(() {
          _roles = roles;
          _templates = templates;
          _allowedTemplates = allowed;

          if (widget.templateMembers != null) {
            final roleIds = widget.templateMembers!.map((m) => m.roleId).toSet();
            _selectedRoles = _roles.where((r) => roleIds.contains(r.id)).toList();
            
            final templateId = widget.templateMembers!.first.messageTemplateId;
            _selectedTemplate = _templates.where((t) => t.id == templateId).firstOrNull;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _updateAllowedTemplates(String parameter) async {
    try {
      final ruleRepo = ref.read(ruleRepositoryProvider);
      final allowed = await ruleRepo.getTemplatesByParameter(parameter);
      
      if (mounted) {
        setState(() {
          _allowedTemplates = allowed;
          if (_selectedTemplate != null && !allowed.any((t) => t['id'] == _selectedTemplate!.id)) {
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


    bool success;
    if (widget.roster != null) {
      success = await ref.read(roasterNotifierProvider.notifier).updateRoster(widget.roster!.id, data);
    } else {
      success = await ref.read(roasterNotifierProvider.notifier).createRoster(data);
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Roster ${widget.roster != null ? 'updated' : 'created'} successfully')),
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
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
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
                                  widget.roster != null ? 'Edit Roster' : 'Create New Roster',
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                  onChanged: (list) => setState(() => _selectedRoles = list),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                                setState(() => _selectedParameter = v);
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildLabel('MESSAGE TEMPLATE'),
                                          const SizedBox(height: 12),
                                          AppDropdown<MessageTemplate>(
                                            value: _selectedTemplate,
                                            items: _templates.where((t) => _allowedTemplates.any((at) => at['id'] == t.id)).toList(),
                                            hint: 'Select Template',
                                            itemLabel: (t) => t.name,
                                            onChanged: (v) => setState(() => _selectedTemplate = v),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            widget.roster != null ? 'UPDATE ROSTER' : 'CREATE ROSTER',
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
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF92400E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Specify the details of the team to begin adding contacts and configuring notification rules later.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF92400E)),
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
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
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
