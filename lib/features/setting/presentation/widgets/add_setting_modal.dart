import 'package:air_water/features/product/provider/product_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../../core/user_config/user_role.dart';
import '../model/setting_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_multi_select_dropdown.dart';
import '../controller/setting_provider.dart';
import '../../../company/presentation/model/company_model.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../site/presentation/model/site_model.dart';
import '../../../site/presentation/controller/site_provider.dart';
import '../../../message_template/presentation/model/message_template_model.dart';
import '../../../message_template/presentation/controller/message_template_provider.dart';
import '../../../tank/presentation/model/tank_model.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../product/data/product_model.dart';
import '../../../../core/network/http/api_service.dart';

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
  final TextEditingController threshold3Controller;
  final TextEditingController statusLabelController;
  MessageTemplate? selectedTemplate;
  List<StrappingPoint> selectedPoints;

  SettingRowData({
    this.parameterType = 'LEVEL',
    this.conditionType = '>',
    String threshold1 = '',
    String threshold2 = '',
    String threshold3 = '',
    String statusLabel = '',
    this.selectedTemplate,
    List<StrappingPoint>? selectedPoints,
  }) : threshold1Controller = TextEditingController(text: threshold1),
       threshold2Controller = TextEditingController(text: threshold2),
       threshold3Controller = TextEditingController(text: threshold3),
       statusLabelController = TextEditingController(text: statusLabel),
       selectedPoints = selectedPoints ?? [];

  void dispose() {
    threshold1Controller.dispose();
    threshold2Controller.dispose();
    threshold3Controller.dispose();
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
  Site? _selectedSite;
  Tank? _selectedTank;
  Product? _selectedProduct;
  int _isActive = 1;

  final List<SettingRowData> _rows = [];

  List<CompanyGroup> _companyGroups = [];
  List<Site> _sites = [];
  List<Tank> _tanks = [];
  List<Product> _products = [];
  List<MessageTemplate> _templates = [];
  bool _isLoadingData = false;

  final _allCompanyGroup = CompanyGroup(
    name: 'ALL',
    addresses: [CompanyAddress(status: 1, companyId: 0)],
  );

  final _allSite = Site(
    id: 0,
    name: 'ALL',
    status: 1,
    companyId: 0,
  );

  final _allTank = Tank(
    tankId: 0,
    tankNumber: 'ALL',
    status: 1,
    siteId: 0,
  );

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
          parameterType: (s.parameterType ?? 'LEVEL').toUpperCase() == 'MFACTOR'
              ? 'MFACTOR'
              : (s.parameterType ?? 'LEVEL'),
          conditionType: s.conditionType ?? '>',
          threshold1: (s.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
              ? (s.threshold1?.toInt().toString().padLeft(2, '0') ?? '00')
              : (s.threshold1?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                  '0'),
          threshold2: (s.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
              ? (s.threshold2?.toInt().toString().padLeft(2, '0') ?? '00')
              : (s.threshold2?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                  '0'),
          threshold3: s.threshold_3?.toString().replaceAll(RegExp(r'\.0$'), '') ??
              '0',
          statusLabel: s.statusLabel ?? '',
        ),
      );
    } else {
      _rows.add(SettingRowData());
    }

    Future.microtask(() => _loadData(productNotifierProvider));
  }

  Future<void> _fetchFullTankDetails(Tank t) async {
    if (t.strappingPoints != null && t.strappingPoints!.isNotEmpty) return;

    setState(() => _isLoadingData = true);
    try {
      final tankRepo = ref.read(tankRepositoryProvider);
      final fullTank = await tankRepo.getTankById(t.tankId);
      setState(() {
        _selectedTank = fullTank;
        // Also update the tank in the local list so we don't fetch it again
        final index = _tanks.indexWhere((tank) => tank.tankId == t.tankId);
        if (index != -1) {
          _tanks[index] = fullTank;
        }
      });
    } catch (e) {
      debugPrint('Error fetching full tank details: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadData(dynamic productListProvider) async {
    setState(() => _isLoadingData = true);
    try {
      final companyRepo = ref.read(companyRepositoryProvider);
      final siteRepo = ref.read(siteRepositoryProvider);
      final templateRepo = ref.read(messageTemplateRepositoryProvider);
      final tankRepo = ref.read(tankRepositoryProvider);

      final results = await Future.wait([
        companyRepo.getGroupedCompanies(limit: 1000),
        siteRepo.getSites(limit: 1000),
        ref.read(allTanksProvider.future),
        ref.refresh(activeTemplatesProvider.future),
        ref.read(productListProvider.future),
      ]);

      setState(() {
        _companyGroups = (results[0] as CompanyGroupedResponse).data;
        _sites = (results[1] as SiteResponse).data;
        _tanks = results[2] as List<Tank>;
        _templates = results[3] as List<MessageTemplate>;
        _products = results[4] as List<Product>;

        if (widget.initialSetting != null) {
          final s = widget.initialSetting!;
          _selectedCompanyGroup = _companyGroups
              .where((g) => g.addresses.any((a) => a.companyId == s.companyId))
              .firstOrNull;

          // Fallback: match by company name when companyId match fails
          if (_selectedCompanyGroup == null &&
              s.companyName != null &&
              s.companyName!.isNotEmpty) {
            _selectedCompanyGroup = _companyGroups
                .where(
                  (g) =>
                      g.name.trim().toLowerCase() ==
                      s.companyName!.trim().toLowerCase(),
                )
                .firstOrNull;
          }

          if (s.siteId != null) {
            _selectedSite = _sites.where((p) => p.id == s.siteId).firstOrNull;
          }

          if (s.tankId != null) {
            _selectedTank = _tanks
                .where((t) => t.tankId == s.tankId)
                .firstOrNull;
          }

          if (s.productId != null) {
            _selectedProduct = _products
                .where((p) => p.id == s.productId)
                .firstOrNull;
          } else if (_selectedTank?.productId != null &&
              _selectedTank?.productId != 0) {
            _selectedProduct = _products
                .where((p) => p.id == _selectedTank!.productId)
                .firstOrNull;
          }

          if (s.messageTemplateId != null && _rows.isNotEmpty) {
            _rows[0].selectedTemplate = _templates
                .where((t) => t.id == s.messageTemplateId)
                .firstOrNull;
          }

          _deviceIdController.text =
              s.deviceId ?? _selectedTank?.deviceId ?? '';
          _simNumberController.text =
              s.simNumber ?? _selectedTank?.simNumber ?? '';
          _timeZoneController.text =
              s.timeZone ?? _selectedTank?.timeZone ?? '';
        } else {
          // New Setting Mode: Auto-select if only one tank is available
          if (_tanks.length == 1) {
            _selectedTank = _tanks[0];
            _selectedSite = _sites
                .where((p) => p.id == _selectedTank!.siteId)
                .firstOrNull;
            _selectedCompanyGroup = _companyGroups
                .where(
                  (g) => g.addresses.any(
                    (a) => a.companyId == _selectedTank!.companyId,
                  ),
                )
                .firstOrNull;
            _deviceIdController.text = _selectedTank?.deviceId ?? '';
            _simNumberController.text = _selectedTank?.simNumber ?? '';
            _timeZoneController.text = _selectedTank?.timeZone ?? '';
            _fetchFullTankDetails(_selectedTank!);
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<bool> _save({bool silent = false}) async {
    if (_nameController.text.trim().isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter Setting Name')),
        );
      }
      return false;
    }
    if (_selectedCompanyGroup == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Company')),
        );
      }
      return false;
    }

    final userRole = ref.read(userRoleProvider).asData?.value;
    final isSuperOrCompany =
        userRole == UserRole.superAdmin || userRole == UserRole.companyAdmin;

    if (isSuperOrCompany) {
      if (_selectedSite == null) {
        if (!silent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Site is required')));
        }
        return false;
      }
      if (_selectedTank == null) {
        if (!silent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tank is required')));
        }
        return false;
      }
    }

    final companyId = _selectedCompanyGroup?.name == 'ALL'
        ? 0
        : _selectedCompanyGroup!.addresses.first.companyId;
    final notifier = ref.read(settingProvider.notifier);
    bool allSuccess = true;

    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'company_id': companyId,
        'plant_id': _selectedSite?.id ?? 0,
        'tank_id': _selectedTank?.tankId ?? 0,
        'product_id': _selectedProduct?.id,
        'parameter_type': row.parameterType,
        'condition_type': row.conditionType,
        'thresholds': [
          double.tryParse(row.threshold1Controller.text.trim()),
          double.tryParse(row.threshold2Controller.text.trim()),
          double.tryParse(row.threshold3Controller.text.trim()),
        ],
        'threshold_1': double.tryParse(row.threshold1Controller.text.trim()),
        'threshold_2': double.tryParse(row.threshold2Controller.text.trim()),
        'threshold_3': double.tryParse(row.threshold3Controller.text.trim()),

        'status_label': row.statusLabelController.text.trim().isEmpty
            ? null
            : row.statusLabelController.text.trim(),
        'message_template_id': row.selectedTemplate?.id,
        'sim_number': _simNumberController.text.trim().isEmpty
            ? null
            : _simNumberController.text.trim(),
        'time_zone': _timeZoneController.text.trim().isEmpty
            ? null
            : _timeZoneController.text.trim(),
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
      if (!silent) {
        final row1 = _rows.isNotEmpty ? _rows[0] : null;
        final paramType = (row1?.parameterType ?? '').toUpperCase().trim();
        final statusLabel = row1?.statusLabelController.text.trim() ?? '';
        // For LEVEL: only send to device when status label is 'ReOrder'
        final shouldSendToDevice = paramType == 'LEVEL'
            ? (statusLabel.toLowerCase() == 'reorder' &&
                  _deviceIdController.text.isNotEmpty)
            : ((paramType == 'CAL TANK' ||
                      paramType == 'CAL KILO LITER' ||
                      paramType == 'SETCALBAR' ||
                      paramType == 'SETBAR' ||
                      paramType == 'SENSOR' ||
                      paramType == 'SENSOR RATING' ||
                      paramType == 'DATA INTERVAL' ||
                      paramType == 'BATTERY' ||
                      paramType == 'SOLAR' ||
                      paramType == 'MFACTOR' ||
                      paramType == 'CHART DATA') &&
                                          paramType != 'DEVICE COMMUNICATE FAILED' &&
                  _deviceIdController.text.isNotEmpty);
        if (shouldSendToDevice) {
          await _sendToDevice(skipSave: true);
          return true;
        }

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialSetting != null
                  ? 'Setting updated'
                  : 'Setting(s) created',
            ),
          ),
        );
      }
      return true;
    }
    return false;
  }

  Future<void> _sendToDevice({bool skipSave = false}) async {
    final userRole = ref.read(userRoleProvider).asData?.value;
    final isSuperOrCompany =
        userRole == UserRole.superAdmin || userRole == UserRole.companyAdmin;

    if (isSuperOrCompany) {
      if (_selectedSite == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Site is required')));
        return;
      }
      if (_selectedTank == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tank is required')));
        return;
      }
    }
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device ID is required to send configuration'),
        ),
      );
      return;
    }

    setState(() => _isLoadingData = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      final productName = _selectedProduct?.name ?? 'N/A';
      final scmM3 = _selectedProduct?.scmM3.toString() ?? '0.0';
      final specificGravity =
          _selectedProduct?.specificGravity.toString() ?? '0.0';

      final row1 = _rows.isNotEmpty ? _rows[0] : null;
      final param1 = row1?.parameterType ?? 'N/A';
      final cond1 = row1?.conditionType ?? 'N/A';
      final thresh1 = row1?.threshold1Controller.text.trim() ?? '0';
      final thresh2 = row1?.threshold2Controller.text.trim() ?? '0';
      final thresh3 = row1?.threshold3Controller.text.trim() ?? '0';

      final simNumber = _simNumberController.text.trim().isEmpty
          ? 'N/A'
          : _simNumberController.text.trim();

      final allParams = _rows.map((r) => r.parameterType).toSet().join('/');

      String payload;
      if (param1 == 'LEVEL') {
        payload = 'ReOrderLevel,$thresh1';
      } else if (param1 == 'CAL TANK') {
        final val1 = ((double.tryParse(thresh1) ?? 0) * 100000).toInt();
        final val2 = ((double.tryParse(thresh2) ?? 0) * 100000).toInt();
        payload = 'CALTANK,1,$val1,$val2';
      } else if (param1 == 'CAL KILO LITER') {
        payload = 'CALLTRS,1,$thresh1,$thresh2';
      } else if (param1 == 'SETCALBAR' || param1 == 'SETBAR') {
        payload = 'SETCALIBBAR,1,$thresh1';
      } else if (param1.toUpperCase().trim() == 'MFACTOR') {
        payload = 'MRATIO,1,$thresh1,$thresh2,$thresh3';
      } else if (param1.toUpperCase().trim() == 'SENSOR' ||
          param1.toUpperCase().trim() == 'SENSOR RATING') {
        final productCode = _selectedProduct?.productCode ?? 'N/A';
        final tonnes = (_selectedTank?.tonnes ?? 0.0).toStringAsFixed(2);
        payload = 'SENSORRATING,1,$thresh1,$productCode,$thresh2,$tonnes,0';
      } else if (param1.toUpperCase().trim() == 'DATA INTERVAL') {
        final hh = int.tryParse(thresh1) ?? 0;
        final mm = int.tryParse(thresh2) ?? 0;
        final hhStr = hh.toString().padLeft(2, '0');
        final mmStr = mm.toString().padLeft(2, '0');
        payload = 'DATAINTERVAL,$hhStr$mmStr';
      } else if (param1.toUpperCase().trim() == 'BATTERY') {
        payload = 'BATVOLTCAL,1,$thresh1';
      } else if (param1.toUpperCase().trim() == 'SOLAR') {
        payload = 'SOLARVOLTCAL,1,$thresh1';
      } else if (param1.toUpperCase().trim() == 'CHART DATA') {
        final pointsData =
            row1?.selectedPoints
                .map((p) => '${p.levelMm.toInt()},${p.volumeM3.toInt()}')
                .join(',') ??
            '';
        payload = '{"\"chartdata\"",$pointsData,9999,9999}';
      } else {
        payload =
            '$productName,$scmM3,$specificGravity,$param1,$cond1,$thresh1,$thresh2,$thresh3,N/A,$deviceId,$simNumber,$allParams';
      }

      final response = await apiClient.post(
        '/mqtt/send-command',
        data: {
          'deviceId': deviceId,
          'sms': payload,
          'parameter_type': param1,
          'status_label': row1?.statusLabelController.text.trim() ?? '',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          bool saveSuccess = true;
          if (!skipSave) {
            saveSuccess = await _save(silent: true);
          }

          if (mounted) {
            if (saveSuccess) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Configuration sent and setting updated successfully',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Configuration sent but failed to update setting in database',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to send command: ${response.data['message'] ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending to device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Site> filteredSites = [];
    if (_selectedCompanyGroup != null) {
      final companyIds = _selectedCompanyGroup!.addresses
          .map((a) => a.companyId)
          .toList();
      filteredSites = [
        _allSite,
        ..._sites.where((p) => companyIds.contains(p.companyId)).toList(),
      ];
    } else {
      filteredSites = [_allSite];
    }

    final companyIds = _selectedCompanyGroup?.name == 'ALL'
        ? <int>[]
        : _selectedCompanyGroup?.addresses.map((a) => a.companyId ?? 0).toList() ??
            <int>[];

    final tanksForCompany = companyIds.isEmpty
        ? _tanks
        : _tanks.where((t) => companyIds.contains(t.companyId)).toList();

    final bool isEditMode = widget.initialSetting != null;

    final roleAsync = ref.watch(userRoleProvider);
    final isCustomer = roleAsync.when(
      data: (role) => role == UserRole.customer,
      loading: () => false,
      error: (_, __) => false,
    );

    final isSuperOrCompanyAdmin = roleAsync.when(
      data: (role) =>
          role == UserRole.superAdmin || role == UserRole.companyAdmin,
      loading: () => false,
      error: (_, __) => false,
    );

    final canSendToDevice = roleAsync.when(
      data: (role) => role == UserRole.customer,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isEditMode
                                        ? (isCustomer
                                              ? 'Edit Setting Configuration'
                                              : 'Edit Rule Configuration')
                                        : (isCustomer
                                              ? 'Create New Setting'
                                              : 'Create New Rule'),
                                    style: GoogleFonts.outfit(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close_rounded),
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildLabelField(
                                isCustomer ? 'SETTING NAME' : 'RULE NAME',
                                AppTextField(
                                  controller: _nameController,
                                  hint: isCustomer
                                      ? 'e.g. Critical Tank Level Low'
                                      : 'e.g. High Pressure Warning',
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (isEditMode) ...[
                                if (!isSuperOrCompanyAdmin) ...[
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
                                ],
                                Row(
                                  children: [
                                    if (!isSuperOrCompanyAdmin) ...[
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
                                    ],
                                    Expanded(
                                      child: _buildLabelField(
                                        isSuperOrCompanyAdmin
                                            ? 'TANK'
                                            : 'TANK (OPTIONAL)',
                                        (isCustomer && isEditMode)
                                            ? AppTextField(
                                                readOnly: true,
                                                controller:
                                                    TextEditingController(
                                                      text:
                                                          _selectedTank
                                                              ?.tankNumber ??
                                                          'N/A',
                                                    ),
                                                hint: 'Tank Name',
                                              )
                                            : AppDropdown<Tank>(
                                                value: _selectedTank,
                                                  items: [
                                                    _allTank,
                                                    ...((_selectedSite == null &&
                                                            !isCustomer)
                                                        ? []
                                                        : tanksForCompany.where(
                                                            (t) =>
                                                                isCustomer ||
                                                                _selectedSite ==
                                                                    null ||
                                                                _selectedSite!
                                                                        .id ==
                                                                    0 ||
                                                                t.siteId ==
                                                                    _selectedSite!
                                                                        .id,
                                                          )),
                                                  ],
                                                hint:
                                                    (_selectedSite == null &&
                                                        !isCustomer)
                                                    ? 'Select Site First'
                                                    : 'Select Tank',
                                                itemLabel: (t) => t.tankNumber,
                                                onChanged:
                                                    (_selectedSite == null &&
                                                        !isCustomer)
                                                    ? null
                                                    : (t) {
                                                        setState(() {
                                                          _selectedTank = t;
                                                          if (t != null) {
                                                            _deviceIdController
                                                                    .text =
                                                                t.deviceId ??
                                                                '';
                                                            _simNumberController
                                                                    .text =
                                                                t.simNumber ??
                                                                '';
                                                            _timeZoneController
                                                                    .text =
                                                                t.timeZone ??
                                                                '';
                                                            if (t.productId !=
                                                                    null &&
                                                                t.productId !=
                                                                    0) {
                                                              _selectedProduct = _products
                                                                  .where(
                                                                    (p) =>
                                                                        p.id ==
                                                                        t.productId,
                                                                  )
                                                                  .firstOrNull;
                                                            }
                                                          }
                                                        });
                                                        if (t != null) {
                                                          _fetchFullTankDetails(
                                                            t,
                                                          );
                                                        }
                                                      },
                                              ),
                                      ),
                                    ),
                                    if (isSuperOrCompanyAdmin) const Spacer(),
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
                                          items: [_allCompanyGroup, ..._companyGroups],
                                          hint: 'Select Company',
                                          itemLabel: (cg) =>
                                              cg.name.trim().isNotEmpty
                                              ? cg.name.trim()
                                              : '(Unnamed Company)',
                                          onChanged: (cg) => setState(() {
                                            _selectedCompanyGroup = cg;
                                            _selectedSite = null;
                                            _selectedTank = null;
                                          }),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _buildLabelField(
                                        isSuperOrCompanyAdmin
                                            ? 'SITE'
                                            : 'SITE (OPTIONAL)',
                                        AppDropdown<Site>(
                                          value: _selectedSite,
                                          items: filteredSites,
                                          hint: 'Select Site',
                                          itemLabel: (p) => p.name,
                                          onChanged: (p) => setState(() {
                                            _selectedSite = p;
                                            _selectedTank = null;
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                              if (!isCustomer && !isEditMode) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLabelField(
                                        isSuperOrCompanyAdmin
                                            ? 'TANK'
                                            : 'TANK (OPTIONAL)',
                                        AppDropdown<Tank>(
                                          value: _selectedTank,
                                          items: [
                                            _allTank,
                                            ...(_selectedSite == null
                                                ? []
                                                : tanksForCompany.where(
                                                    (t) =>
                                                        _selectedSite!.id ==
                                                            0 ||
                                                        t.siteId ==
                                                            _selectedSite!.id,
                                                  )),
                                          ],
                                          hint: _selectedSite == null
                                              ? 'Select Site First'
                                              : 'Select Tank',
                                          itemLabel: (t) => t.tankNumber,
                                          onChanged: _selectedSite == null
                                              ? null
                                              : (t) {
                                                  setState(() {
                                                    _selectedTank = t;
                                                    if (t != null) {
                                                      _deviceIdController.text =
                                                          t.deviceId ?? '';
                                                      _simNumberController
                                                              .text =
                                                          t.simNumber ?? '';
                                                      _timeZoneController.text =
                                                          t.timeZone ?? '';

                                                      if (t.productId != null &&
                                                          t.productId != 0) {
                                                        _selectedProduct =
                                                            _products
                                                                .where(
                                                                  (p) =>
                                                                      p.id ==
                                                                      t.productId,
                                                                )
                                                                .firstOrNull;
                                                      }
                                                    }
                                                  });
                                                  if (t != null) {
                                                    _fetchFullTankDetails(t);
                                                  }
                                                },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (!isSuperOrCompanyAdmin &&
                                  !(isCustomer && !isEditMode)) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildLabelField(
                                        'PRODUCT NAME',
                                        isCustomer
                                            ? AppTextField(
                                                readOnly: true,
                                                controller:
                                                    TextEditingController(
                                                      text:
                                                          _selectedProduct
                                                              ?.name ??
                                                          'N/A',
                                                    ),
                                                hint: 'Product Name',
                                              )
                                            : AppDropdown<Product>(
                                                value: _selectedProduct,
                                                items: _products,
                                                hint: 'Select Product',
                                                itemLabel: (p) => p.name,
                                                onChanged: (p) => setState(
                                                  () => _selectedProduct = p,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildLabelField(
                                        'SCM / M3',
                                        AppTextField(
                                          readOnly: true,
                                          controller: TextEditingController(
                                            text:
                                                _selectedProduct?.scmM3
                                                    .toString() ??
                                                '0.0',
                                          ),
                                          hint: 'SCM / M3',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildLabelField(
                                        'SPECIFIC GRAVITY',
                                        AppTextField(
                                          readOnly: true,
                                          controller: TextEditingController(
                                            text:
                                                _selectedProduct
                                                    ?.specificGravity
                                                    .toString() ??
                                                '0.0',
                                          ),
                                          hint: 'Specific Gravity',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_selectedProduct != null) ...[
                                  const SizedBox(height: 16),
                                  _buildLabelField(
                                    'PRODUCT DESCRIPTION',
                                    AppTextField(
                                      readOnly: true,
                                      controller: TextEditingController(
                                        text: _selectedProduct!.description,
                                      ),
                                      hint: 'No description available',
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Configuration Set ${index + 1}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF141E7A),
                                          ),
                                        ),
                                        if (!isEditMode && _rows.length > 1)
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                row.dispose();
                                                _rows.removeAt(index);
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            label: Text(
                                              'Remove',
                                              style: GoogleFonts.inter(
                                                color: Colors.red,
                                                fontSize: 13,
                                              ),
                                            ),
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
                                              items: const [
                                                'LEVEL',
                                                'BATTERY',
                                                'PRESSURE',
                                                'TEMPERATURE',
                                                'FLOW',
                                                'CAL TANK',
                                                'CAL KILO LITER',
                                                'SENSOR',
                                                'SETBAR',
                                                'SETCALBAR',
                                                'MFACTOR',
                                                'DATA INTERVAL',
                                                'CHART DATA',
                                                'SOLAR',
                                                'DEVICE COMMUNICATE FAILED',
                                                'OTHER',
                                              ],
                                              hint: 'Select Param',
                                              itemLabel: (v) => v,
                                              onChanged: (v) {
                                                setState(() {
                                                  final prevType = row
                                                      .parameterType
                                                      .toUpperCase()
                                                      .trim();
                                                  row.parameterType = v!;
                                                  // Reset status label when switching from LEVEL to another type
                                                  // to avoid stale dropdown values appearing in the free-text field
                                                  if (prevType == 'LEVEL' &&
                                                      v.toUpperCase().trim() !=
                                                          'LEVEL') {
                                                    row.statusLabelController
                                                        .clear();
                                                  }
                                                });
                                                if (v == 'CHART DATA' &&
                                                    _selectedTank != null) {
                                                  _fetchFullTankDetails(
                                                    _selectedTank!,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        if (![
                                          'CAL TANK',
                                          'CAL KILO LITER',
                                          'SENSOR',
                                          'SENSOR RATING',
                                          'MFACTOR',
                                          'SETBAR',
                                          'SETCALBAR',
                                          'CHART DATA',
                                          'DATA INTERVAL',
                                        ].contains(
                                          row.parameterType
                                              .toUpperCase()
                                              .trim(),
                                        )) ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: _buildLabelField(
                                              'CONDITION',
                                              AppDropdown<String>(
                                                value: row.conditionType,
                                                items: const [
                                                  '<',
                                                  '>',
                                                  '<=',
                                                  '>=',
                                                  '==',
                                                  '!=',
                                                  'BETWEEN',
                                                ],
                                                hint: 'Select Type',
                                                itemLabel: (v) => v,
                                                onChanged: (v) => setState(
                                                  () => row.conditionType = v!,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (row.parameterType
                                                  .toUpperCase()
                                                  .trim() !=
                                              'SOLAR') ...[
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 4,
                                              child: _buildLabelField(
                                                'STATUS LABEL (UI DISPLAY)',
                                                // For LEVEL & BATTERY: use predefined dropdown; for other types: free text
                                                (row.parameterType
                                                                .toUpperCase()
                                                                .trim() ==
                                                            'LEVEL' ||
                                                        row.parameterType
                                                                .toUpperCase()
                                                                .trim() ==
                                                            'BATTERY')
                                                    ? AppDropdown<String>(
                                                        value: () {
                                                          const allowed = [
                                                            'ReOrder',
                                                            'Critical',
                                                            'Low',
                                                            'High',
                                                          ];
                                                          final current = row
                                                              .statusLabelController
                                                              .text;
                                                          if (allowed.contains(
                                                            current,
                                                          ))
                                                            return current;
                                                          // Mapping existing values to prevent crash
                                                          final upper = current
                                                              .toUpperCase();
                                                          if (upper ==
                                                              'REORDER')
                                                            return 'ReOrder';
                                                          if (upper ==
                                                              'CRITICAL')
                                                            return 'Critical';
                                                          if (upper.contains(
                                                            'LOW',
                                                          ))
                                                            return 'Low';
                                                          if (upper.contains(
                                                            'HIGH',
                                                          ))
                                                            return 'High';
                                                          return null;
                                                        }(),
                                                        items:
                                                            (row.parameterType
                                                                    .toUpperCase()
                                                                    .trim() ==
                                                                'BATTERY')
                                                            ? const [
                                                                'Critical',
                                                                'Low',
                                                                'High',
                                                              ]
                                                            : const [
                                                                'ReOrder',
                                                                'Critical',
                                                                'Low',
                                                                'High',
                                                              ],
                                                        hint: 'Select Label',
                                                        itemLabel: (v) => v,
                                                        onChanged: (v) => setState(
                                                          () =>
                                                              row
                                                                      .statusLabelController
                                                                      .text =
                                                                  v ?? '',
                                                        ),
                                                      )
                                                    : AppTextField(
                                                        controller: row
                                                            .statusLabelController,
                                                        hint: 'e.g. LOW LEVEL',
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildLabelField(
                                            (row.parameterType
                                                            .toUpperCase()
                                                            .trim() ==
                                                        'SENSOR' ||
                                                    row.parameterType
                                                            .toUpperCase()
                                                            .trim() ==
                                                        'SENSOR RATING')
                                                ? 'SENSOR RATING'
                                                : (row.parameterType
                                                              .toUpperCase()
                                                              .trim() ==
                                                          'BATTERY' ||
                                                      row.parameterType
                                                              .toUpperCase()
                                                              .trim() ==
                                                          'SOLAR')
                                                ? 'VOLTAGE'
                                                : (row.parameterType.toUpperCase().trim() == 'DATA INTERVAL')
                                                    ? 'Hours'
                                                    : (row.parameterType.toUpperCase().trim() == 'DEVICE COMMUNICATE FAILED')
                                                        ? 'Minutes'
                                                    : ([
                                                        'CAL TANK',
                                                        'CAL KILO LITER',
                                                        'MFACTOR',
                                                        'SETBAR',
                                                        'SETCALBAR',
                                                      ].contains(
                                                        row.parameterType
                                                            .toUpperCase()
                                                            .trim(),
                                                      ))
                                                        ? '${row.parameterType} 1'
                                                        : (row.parameterType.toUpperCase().trim() == 'CHART DATA')
                                                            ? 'Field 1'
                                                            : (row.conditionType ==
                                                                      'BETWEEN'
                                                                  ? 'MIN THRESHOLD'
                                                                  : 'THRESHOLD VALUE'),
                                            row.parameterType
                                                        .toUpperCase()
                                                        .trim() ==
                                                    'CHART DATA'
                                                ? AppMultiSelectDropdown<
                                                    StrappingPoint
                                                  >(
                                                    selectedItems:
                                                        row.selectedPoints,
                                                    items:
                                                        _selectedTank
                                                            ?.strappingPoints ??
                                                        [],
                                                    hint: _selectedTank == null
                                                        ? 'Select Tank First'
                                                        : (_selectedTank!
                                                                      .strappingPoints ==
                                                                  null ||
                                                              _selectedTank!
                                                                  .strappingPoints!
                                                                  .isEmpty)
                                                        ? 'No Points Available'
                                                        : 'Select Point(s)',
                                                    itemLabel: (p) =>
                                                        'L: ${p.levelMm} | V: ${p.volumeM3}',
                                                    onChanged: (list) {
                                                      setState(() {
                                                        row.selectedPoints =
                                                            list;
                                                        row
                                                            .threshold1Controller
                                                            .text = list
                                                            .map(
                                                              (p) => p.levelMm,
                                                            )
                                                            .join(',');
                                                        row
                                                            .threshold2Controller
                                                            .text = list
                                                            .map(
                                                              (p) => p.volumeM3,
                                                            )
                                                            .join(',');
                                                      });
                                                    },
                                                  )
                                                : AppTextField(
                                                    controller: row
                                                        .threshold1Controller,
                                                    hint: 'Value',
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                  ),
                                          ),
                                        ),
                                        if (row.conditionType == 'BETWEEN' ||
                                            [
                                              'CAL TANK',
                                              'CAL KILO LITER',
                                              'SENSOR',
                                              'SENSOR RATING',
                                              'MFACTOR',
                                              'DATA INTERVAL',
                                            ].contains(
                                              row.parameterType
                                                  .toUpperCase()
                                                  .trim(),
                                            )) ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: _buildLabelField(
                                              (row.parameterType
                                                              .toUpperCase()
                                                              .trim() ==
                                                          'SENSOR' ||
                                                      row.parameterType
                                                              .toUpperCase()
                                                              .trim() ==
                                                          'SENSOR RATING')
                                                  ? 'CUBIC METER'
                                                  : (row.parameterType.toUpperCase().trim() == 'DATA INTERVAL')
                                                      ? 'Minutes'
                                                      : ([
                                                          'CAL TANK',
                                                          'CAL KILO LITER',
                                                          'MFACTOR',
                                                        ].contains(
                                                          row.parameterType
                                                              .toUpperCase()
                                                              .trim(),
                                                        ))
                                                          ? '${row.parameterType} 2'
                                                          : 'MAX THRESHOLD',
                                              AppTextField(
                                                controller:
                                                    row.threshold2Controller,
                                                hint: 'Value',
                                                readOnly:
                                                    row.parameterType
                                                        .toUpperCase()
                                                        .trim() ==
                                                    'CHART DATA',
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (row.parameterType
                                                .toUpperCase()
                                                .trim() ==
                                            'MFACTOR') ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 2,
                                            child: _buildLabelField(
                                              '${row.parameterType} 3',
                                              AppTextField(
                                                controller:
                                                    row.threshold3Controller,
                                                hint: 'Value',
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (!isCustomer &&
                                        ![
                                          'CAL TANK',
                                          'CAL KILO LITER',
                                          'SENSOR',
                                          'SENSOR RATING',
                                          'MFACTOR',
                                          'SETBAR',
                                          'SETCALBAR',
                                          'CHART DATA',
                                          'DATA INTERVAL',
                                          'SOLAR',
                                          'TEMPERATURE',
                                          'FLOW',
                                        ].contains(
                                          row.parameterType
                                              .toUpperCase()
                                              .trim(),
                                        )) ...[
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
                                                onChanged: (t) => setState(
                                                  () =>
                                                      row.selectedTemplate = t,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Spacer(flex: 2),
                                        ],
                                      ),
                                    ],
                                    if (index < _rows.length - 1)
                                      const Divider(height: 32),
                                  ],
                                );
                              }),
                              const SizedBox(height: 24),
                              if (!isEditMode)
                                OutlinedButton.icon(
                                  onPressed: () => setState(
                                    () => _rows.add(SettingRowData()),
                                  ),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFF141E7A),
                                  ),
                                  label: Text(
                                    'ADD ANOTHER CONFIGURATION',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF141E7A),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF141E7A),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 32),
                              _buildStatusSection(),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  if (canSendToDevice && !isEditMode && (_rows.isEmpty || _rows[0].parameterType.toUpperCase().trim() != 'DEVICE COMMUNICATE FAILED')) ...[
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _sendToDevice,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[700],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'SEND DEVICE',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
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
                                        onPressed:
                                            (isCustomer &&
                                                canSendToDevice &&
                                                isEditMode)
                                            ? _sendToDevice
                                            : _save,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF141E7A,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                          child: Text(
                                            isEditMode
                                                ? (isCustomer
                                                      ? 'SEND DEVICE'
                                                      : 'UPDATE RULE')
                                                : (isCustomer
                                                      ? (_rows.isNotEmpty &&
                                                              _rows[0]
                                                                      .parameterType
                                                                      .toUpperCase()
                                                                      .trim() ==
                                                                  'DEVICE COMMUNICATE FAILED'
                                                          ? 'CREATE SETTING'
                                                          : 'SEND DEVICE')
                                                      : 'CREATE RULE'),
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
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
        Text(
          'STATUS CONFIGURATION',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF141E7A),
            letterSpacing: 1.2,
          ),
        ),
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
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xFF333333),
            letterSpacing: 0.5,
          ),
        ),
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
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}
