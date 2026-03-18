import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/rule_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/rule_provider.dart';
import '../../../company/presentation/model/company_model.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../../plant/presentation/controller/plant_provider.dart';
import '../../../message_template/presentation/model/message_template_model.dart';
import '../../../message_template/presentation/controller/message_template_provider.dart';

class AddRuleModal extends ConsumerStatefulWidget {
  final Rule? initialRule;

  const AddRuleModal({super.key, this.initialRule});

  @override
  ConsumerState<AddRuleModal> createState() => _AddRuleModalState();
}

class _AddRuleModalState extends ConsumerState<AddRuleModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _threshold1Controller = TextEditingController();
  final _threshold2Controller = TextEditingController();
  final _statusLabelController = TextEditingController();

  CompanyGroup? _selectedCompanyGroup;
  Plant? _selectedPlant;
  MessageTemplate? _selectedTemplate;
  String _parameterType = 'LEVEL';
  String _conditionType = '>';
  String _importance = 'Critical';
  int _isActive = 1;

  List<CompanyGroup> _companyGroups = [];
  List<Plant> _plants = [];
  List<MessageTemplate> _templates = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRule != null) {
      final r = widget.initialRule!;
      _nameController.text = r.name;
      _descriptionController.text = r.description ?? '';
      _threshold1Controller.text = r.threshold1?.toString() ?? '';
      _threshold2Controller.text = r.threshold2?.toString() ?? '';
      _statusLabelController.text = r.statusLabel ?? '';
      _parameterType = r.parameterType ?? 'LEVEL';
      _conditionType = r.conditionType ?? '>';
      _importance = r.importance ?? 'Critical';
      _isActive = r.isActive;
    }
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final companyRepo = ref.read(companyRepositoryProvider);
      final plantRepo = ref.read(plantRepositoryProvider);
      final templateRepo = ref.read(messageTemplateRepositoryProvider);

      final companiesResponse = await companyRepo.getGroupedCompanies(limit: 1000);
      final plantsResponse = await plantRepo.getPlants(limit: 1000);
      final activeTemplates = await templateRepo.getActiveTemplates();

      setState(() {
        _companyGroups = companiesResponse.data;
        _plants = plantsResponse.data;
        _templates = activeTemplates;

        if (widget.initialRule != null) {
          final r = widget.initialRule!;
          // Find selected company group
          _selectedCompanyGroup = _companyGroups.where((g) => g.addresses.any((a) => a.companyId == r.companyId)).firstOrNull;
          // Find selected plant
          if (r.plantId != null) {
            _selectedPlant = _plants.where((p) => p.id == r.plantId).firstOrNull;
          }
          // Find selected template
          if (r.messageTemplateId != null) {
            _selectedTemplate = _templates.where((t) => t.id == r.messageTemplateId).firstOrNull;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Rule Name')));
      return;
    }
    if (_selectedCompanyGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Company')));
      return;
    }

    final companyId = _selectedCompanyGroup!.addresses.first.companyId;

    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'company_id': companyId,
      'plant_id': _selectedPlant?.id,
      'parameter_type': _parameterType,
      'condition_type': _conditionType,
      'threshold_1': double.tryParse(_threshold1Controller.text),
      'threshold_2': double.tryParse(_threshold2Controller.text),
      'importance': _importance,
      'status_label': _statusLabelController.text.isEmpty ? null : _statusLabelController.text,
      'message_template_id': _selectedTemplate?.id,
      'is_active': _isActive,
      'status': 1,
    };

    final notifier = ref.read(ruleProvider.notifier);
    bool success;
    if (widget.initialRule != null) {
      success = await notifier.updateRule(widget.initialRule!.id, data);
    } else {
      success = await notifier.createRule(data);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.initialRule != null ? 'Rule updated' : 'Rule created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Plant> filteredPlants = [];
    if (_selectedCompanyGroup != null) {
      final companyIds = _selectedCompanyGroup!.addresses.map((a) => a.companyId).toList();
      filteredPlants = _plants.where((p) => companyIds.contains(p.companyId)).toList();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
        child: SizedBox(
          width: 750,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
              ),
              Expanded(
                child: _isLoadingData && widget.initialRule != null
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.initialRule != null ? 'Edit Rule Configuration' : 'Create New Rule',
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111827),
                                    ),
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
                              _buildLabelField(
                                'RULE NAME',
                                AppTextField(
                                  controller: _nameController,
                                  hint: 'e.g. Critical Tank Level Low',
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLabelField(
                                      'COMPANY',
                                      AppDropdown<CompanyGroup>(
                                        value: _selectedCompanyGroup,
                                        items: _companyGroups,
                                        hint: 'Select Company',
                                        itemLabel: (g) => g.name,
                                        onChanged: (g) {
                                          setState(() {
                                            _selectedCompanyGroup = g;
                                            _selectedPlant = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildLabelField(
                                      'PLANT (OPTIONAL)',
                                      AppDropdown<Plant>(
                                        value: _selectedPlant,
                                        items: filteredPlants,
                                        hint: 'Select Plant',
                                        itemLabel: (p) => p.name,
                                        onChanged: (p) => setState(() => _selectedPlant = p),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              Text(
                                'CONDITION CONFIGURATION',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF141E7A),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildLabelField(
                                      'PARAMETER TYPE',
                                      AppDropdown<String>(
                                        value: _parameterType,
                                        items: const ['LEVEL', 'BATTERY', 'PRESSURE', 'TEMPERATURE', 'FLOW', 'TAG', 'OTHER'],
                                        hint: 'Select Param',
                                        itemLabel: (v) => v,
                                        onChanged: (v) => setState(() => _parameterType = v!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: _buildLabelField(
                                      'CONDITION',
                                      AppDropdown<String>(
                                        value: _conditionType,
                                        items: const ['<', '>', '<=', '>=', '==', '!=', 'BETWEEN'],
                                        hint: 'Select Type',
                                        itemLabel: (v) => v,
                                        onChanged: (v) => setState(() => _conditionType = v!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: _buildLabelField(
                                      'STATUS LABEL (UI DISPLAY)',
                                      AppTextField(
                                        controller: _statusLabelController,
                                        hint: 'e.g. LOW LEVEL',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLabelField(
                                      _conditionType == 'BETWEEN' ? 'MIN THRESHOLD' : 'THRESHOLD VALUE',
                                      AppTextField(
                                        controller: _threshold1Controller,
                                        hint: 'Value',
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                  ),
                                  if (_conditionType == 'BETWEEN') ...[
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildLabelField(
                                        'MAX THRESHOLD',
                                        AppTextField(
                                          controller: _threshold2Controller,
                                          hint: 'Value',
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 40),
                              Text(
                                'ALARM & NOTIFICATION',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF141E7A),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLabelField(
                                      'IMPORTANCE',
                                      AppDropdown<String>(
                                        value: _importance,
                                        items: const ['Critical', 'Warning', 'Urgent', 'Info'],
                                        hint: 'Select Importance',
                                        itemLabel: (v) => v,
                                        onChanged: (v) => setState(() => _importance = v!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  const Expanded(child: SizedBox()), // Placeholder for removed status label
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildLabelField(
                                'MESSAGE TEMPLATE TO TRIGGER',
                                AppDropdown<MessageTemplate>(
                                  value: _selectedTemplate,
                                  items: _templates,
                                  hint: 'Select Template',
                                  itemLabel: (t) => t.name,
                                  onChanged: (t) => setState(() => _selectedTemplate = t),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildStatusSection(),
                              const SizedBox(height: 48),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF141E7A),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    widget.initialRule != null ? 'UPDATE RULE' : 'CREATE RULE',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
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

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS CONFIGURATION',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF141E7A),
            letterSpacing: 1.2,
          ),
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildLabelField(
                'ACTIVE STATUS',
                AppDropdown<int>(
                  value: _isActive,
                  items: const [1, 0],
                  hint: 'Status',
                  itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
                  onChanged: (v) => setState(() => _isActive = v!),
                ),
              ),
            ),
          ],
        ),
      ],
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
            color: const Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        field,
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _threshold1Controller.dispose();
    _threshold2Controller.dispose();
    _statusLabelController.dispose();
    super.dispose();
  }
}
