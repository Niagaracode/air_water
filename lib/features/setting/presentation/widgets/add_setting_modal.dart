import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../../core/user_config/user_role.dart';
import '../model/setting_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controller/setting_provider.dart';
import '../../../company/presentation/model/company_model.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../../../plant/presentation/controller/plant_provider.dart';
import '../../../message_template/presentation/model/message_template_model.dart';
import '../../../message_template/presentation/controller/message_template_provider.dart';
import '../../../tank/presentation/model/tank_model.dart';
import '../../../tank/presentation/controller/tank_provider.dart';

class AddSettingModal extends ConsumerStatefulWidget {
  final Setting? initialSetting;

  const AddSettingModal({super.key, this.initialSetting});

  @override
  ConsumerState<AddSettingModal> createState() => _AddSettingModalState();
}

class SettingRowData {
  String parameterType;
  String conditionType;
  final TextEditingController threshold1Controller;
  final TextEditingController threshold2Controller;
  final TextEditingController statusLabelController;
  String importance;
  MessageTemplate? selectedTemplate;

  SettingRowData({
    this.parameterType = 'LEVEL',
    this.conditionType = '>',
    String threshold1 = '',
    String threshold2 = '',
    String statusLabel = '',
    this.importance = 'Critical',
    this.selectedTemplate,
  }) : threshold1Controller = TextEditingController(text: threshold1),
       threshold2Controller = TextEditingController(text: threshold2),
       statusLabelController = TextEditingController(text: statusLabel);

  void dispose() {
    threshold1Controller.dispose();
    threshold2Controller.dispose();
    statusLabelController.dispose();
  }
}

class _AddSettingModalState extends ConsumerState<AddSettingModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _simNumberController = TextEditingController();
  final _timeZoneController = TextEditingController();

  CompanyGroup? _selectedCompanyGroup;
  Plant? _selectedPlant;
  Tank? _selectedTank;
  int _isActive = 1;

  final List<SettingRowData> _rows = [];

  List<CompanyGroup> _companyGroups = [];
  List<Plant> _plants = [];
  List<Tank> _tanks = [];
  List<MessageTemplate> _templates = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialSetting != null) {
      final s = widget.initialSetting!;
      _nameController.text = s.name;
      _descriptionController.text = s.description ?? '';
      _isActive = s.isActive;

      _rows.add(
        SettingRowData(
          parameterType: s.parameterType ?? 'LEVEL',
          conditionType: s.conditionType ?? '>',
          threshold1: s.threshold1?.toString() ?? '',
          threshold2: s.threshold2?.toString() ?? '',
          statusLabel: s.statusLabel ?? '',
          importance: s.importance ?? 'Critical',
        ),
      );
    } else {
      _rows.add(SettingRowData());
    }

    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final companyRepo = ref.read(companyRepositoryProvider);
      final plantRepo = ref.read(plantRepositoryProvider);
      final templateRepo = ref.read(messageTemplateRepositoryProvider);
      final tankRepo = ref.read(tankRepositoryProvider);

      final companiesResponse = await companyRepo.getGroupedCompanies(limit: 1000);
      final plantsResponse = await plantRepo.getPlants(limit: 1000);
      final tanksResponse = await tankRepo.getTanks();
      final activeTemplates = await templateRepo.getActiveTemplates();

      setState(() {
        _companyGroups = companiesResponse.data;
        _plants = plantsResponse.data;
        _tanks = tanksResponse;
        _templates = activeTemplates;

        if (widget.initialSetting != null) {
          final s = widget.initialSetting!;
          _selectedCompanyGroup = _companyGroups
              .where((g) => g.addresses.any((a) => a.companyId == s.companyId))
              .firstOrNull;

          if (s.plantId != null) {
            _selectedPlant = _plants.where((p) => p.id == s.plantId).firstOrNull;
          }

          if (s.tankId != null) {
            _selectedTank = _tanks.where((t) => t.tankId == s.tankId).firstOrNull;
          }

          if (s.messageTemplateId != null && _rows.isNotEmpty) {
            _rows[0].selectedTemplate = _templates
                .where((t) => t.id == s.messageTemplateId)
                .firstOrNull;
          }

          _deviceIdController.text = s.deviceId ?? _selectedTank?.deviceId ?? '';
          _simNumberController.text = s.simNumber ?? _selectedTank?.simNumber ?? '';
          _timeZoneController.text = s.timeZone ?? _selectedTank?.timeZone ?? '';
        }
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Setting Name')));
      return;
    }
    if (_selectedCompanyGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Company')));
      return;
    }

    final companyId = _selectedCompanyGroup!.addresses.first.companyId;
    final notifier = ref.read(settingProvider.notifier);
    bool allSuccess = true;

    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'company_id': companyId,
        'plant_id': _selectedPlant?.id,
        'tank_id': _selectedTank?.tankId,
        'parameter_type': row.parameterType,
        'condition_type': row.conditionType,
        'threshold_1': double.tryParse(row.threshold1Controller.text.trim()),
        'threshold_2': double.tryParse(row.threshold2Controller.text.trim()),
        'importance': row.importance,
        'status_label': row.statusLabelController.text.trim().isEmpty ? null : row.statusLabelController.text.trim(),
        'message_template_id': row.selectedTemplate?.id,
        'sim_number': _simNumberController.text.trim().isEmpty ? null : _simNumberController.text.trim(),
        'time_zone': _timeZoneController.text.trim().isEmpty ? null : _timeZoneController.text.trim(),
        'is_active': _isActive,
        'status': 1,
      };

      bool success;
      if (widget.initialSetting != null && i == 0) {
        success = await notifier.updateSetting(widget.initialSetting!.id, data);
      } else {
        success = await notifier.createSetting(data);
      }

      if (!success) allSuccess = false;
    }

    if (allSuccess && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialSetting != null ? 'Setting updated' : 'Setting(s) created',
          ),
        ),
      );
    }
  }

  Future<void> _sendToDevice() async {
    setState(() => _isLoadingData = true);
    try {
      // Mock sending to device
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration sent to device successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send to device: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Plant> filteredPlants = [];
    if (_selectedCompanyGroup != null) {
      final companyIds = _selectedCompanyGroup!.addresses.map((a) => a.companyId).toList();
      filteredPlants = _plants.where((p) => companyIds.contains(p.companyId)).toList();
    }

    final bool isEditMode = widget.initialSetting != null;

    final roleAsync = ref.watch(userRoleProvider);
    final isCustomer = roleAsync.when(
      data: (role) => role == UserRole.customer,
      loading: () => false,
      error: (_, __) => false,
    );

    final canSendToDevice = roleAsync.when(
      data: (role) => role != UserRole.superAdmin && role != UserRole.companyAdmin,
      loading: () => false,
      error: (_, __) => false,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
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
                child: _isLoadingData && isEditMode
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                   Text(
                                    isEditMode 
                                        ? (isCustomer ? 'Edit Setting Configuration' : 'Edit Rule Configuration')
                                        : (isCustomer ? 'Create New Setting' : 'Create New Rule'),
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
                              const SizedBox(height: 24),
                               _buildLabelField(isCustomer ? 'SETTING NAME' : 'RULE NAME', AppTextField(controller: _nameController, hint: isCustomer ? 'e.g. Critical Tank Level Low' : 'e.g. High Pressure Warning')),
                              const SizedBox(height: 8),
                              if (isEditMode) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLabelField(
                                        'DEVICE ID',
                                        AppTextField(
                                          controller: _deviceIdController,
                                          hint: 'Device ID',
                                          readOnly: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildLabelField(
                                        'SIM CARD NUMBER',
                                        AppTextField(
                                          controller: _simNumberController,
                                          hint: 'Enter SIM Number',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLabelField(
                                        'TIME ZONE/REGION',
                                        AppTextField(
                                          controller: _timeZoneController,
                                          hint: 'e.g. UTC, Asia/Kolkata',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              const SizedBox(height: 8),
                              if (!isCustomer) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLabelField(
                                        'COMPANY',
                                        AppDropdown<CompanyGroup>(
                                          value: _selectedCompanyGroup,
                                          items: _companyGroups,
                                          hint: 'Select Company',
                                          itemLabel: (cg) => cg.name,
                                          onChanged: (cg) => setState(() {
                                            _selectedCompanyGroup = cg;
                                            _selectedPlant = null;
                                            _selectedTank = null;
                                          }),
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
                                          onChanged: (p) => setState(() {
                                            _selectedPlant = p;
                                            _selectedTank = null;
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                              if (!isCustomer) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLabelField(
                                        'TANK (OPTIONAL)',
                                        AppDropdown<Tank>(
                                          value: _selectedTank,
                                          items: _selectedPlant == null ? [] : _tanks.where((t) => t.plantId == _selectedPlant!.id).toList(),
                                          hint: _selectedPlant == null ? 'Select Plant First' : 'Select Tank',
                                          itemLabel: (t) => t.tankNumber,
                                          onChanged: _selectedPlant == null ? null : (t) => setState(() {
                                            _selectedTank = t;
                                            if (t != null) {
                                              _deviceIdController.text = t.deviceId ?? '';
                                              _simNumberController.text = t.simNumber ?? '';
                                              _timeZoneController.text = t.timeZone ?? '';
                                            }
                                          }),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              const SizedBox(height: 8),
                              const Divider(),
                              ...List.generate(_rows.length, (index) {
                                final row = _rows[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Configuration Set ${index + 1}',
                                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF141E7A)),
                                        ),
                                        if (!isEditMode && _rows.length > 1)
                                          TextButton.icon(
                                            onPressed: () { setState(() { row.dispose(); _rows.removeAt(index); }); },
                                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                            label: Text('Remove', style: GoogleFonts.inter(color: Colors.red, fontSize: 13)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: _buildLabelField(
                                            'PARAMETER TYPE',
                                            AppDropdown<String>(
                                              value: row.parameterType,
                                              items: const ['LEVEL', 'BATTERY', 'PRESSURE', 'TEMPERATURE', 'FLOW', 'OTHER'],
                                              hint: 'Select Param',
                                              itemLabel: (v) => v,
                                              onChanged: (v) => setState(() => row.parameterType = v!),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: _buildLabelField(
                                            'CONDITION',
                                            AppDropdown<String>(
                                              value: row.conditionType,
                                              items: const ['<', '>', '<=', '>=', '==', '!=', 'BETWEEN'],
                                              hint: 'Select Type',
                                              itemLabel: (v) => v,
                                              onChanged: (v) => setState(() => row.conditionType = v!),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 4,
                                          child: _buildLabelField('STATUS LABEL (UI DISPLAY)', AppTextField(controller: row.statusLabelController, hint: 'e.g. LOW LEVEL')),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildLabelField(
                                            row.conditionType == 'BETWEEN' ? 'MIN THRESHOLD' : 'THRESHOLD VALUE',
                                            AppTextField(
                                              controller: row.threshold1Controller,
                                              hint: 'Value',
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            ),
                                          ),
                                        ),
                                        if (row.conditionType == 'BETWEEN') ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: _buildLabelField(
                                              'MAX THRESHOLD',
                                              AppTextField(
                                                controller: row.threshold2Controller,
                                                hint: 'Value',
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: _buildLabelField(
                                            'IMPORTANCE',
                                            AppDropdown<String>(
                                              value: row.importance,
                                              items: const ['Critical', 'Warning', 'Urgent', 'Info'],
                                              hint: 'Select Importance',
                                              itemLabel: (v) => v,
                                              onChanged: (v) => setState(() => row.importance = v!),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isCustomer) ...[
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: _buildLabelField(
                                              'MESSAGE TEMPLATE TO TRIGGER',
                                              AppDropdown<MessageTemplate>(
                                                value: row.selectedTemplate,
                                                items: _templates,
                                                hint: 'Select Template',
                                                itemLabel: (t) => t.name,
                                                onChanged: (t) => setState(() => row.selectedTemplate = t),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Spacer(flex: 2),
                                        ],
                                      ),
                                    ],
                                    if (index < _rows.length - 1) const Divider(height: 32),
                                  ],
                                );
                              }),
                              const SizedBox(height: 24),
                              if (!isEditMode)
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _rows.add(SettingRowData())),
                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF141E7A)),
                                  label: Text('ADD ANOTHER CONFIGURATION', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF141E7A))),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF141E7A)),
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              const SizedBox(height: 32),
                              _buildStatusSection(),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  if (canSendToDevice) ...[
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _sendToDevice,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'SEND DEVICE',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _save,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF141E7A),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          isEditMode 
                                              ? (isCustomer ? 'UPDATE SETTING' : 'UPDATE RULE') 
                                              : (isCustomer ? 'CREATE SETTING' : 'CREATE RULE'), 
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
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
        Text('STATUS CONFIGURATION', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF141E7A), letterSpacing: 1.2)),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: 16),
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
        Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12, color: const Color(0xFF333333), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _deviceIdController.dispose();
    _simNumberController.dispose();
    _timeZoneController.dispose();
    for (var row in _rows) { row.dispose(); }
    super.dispose();
  }
}
