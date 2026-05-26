import 'package:air_water/features/product/provider/product_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../../core/user_config/user_role.dart';
import '../../../tank/data/model/tank_model.dart';
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
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../../product/data/product_model.dart';
import '../../../../core/network/http/api_service.dart';
import '../../../profile/presentation/controller/profile_provider.dart';

class AddSettingModal extends ConsumerStatefulWidget {
  final Setting? initialSetting;
  final Tank? preselectedTank;

  const AddSettingModal({super.key, this.initialSetting, this.preselectedTank});

  @override
  ConsumerState<AddSettingModal> createState() => _AddSettingModalState();
}

class SettingRowData {
  int? id;
  String parameterType;
  String conditionType;
  final TextEditingController threshold1Controller;
  final TextEditingController threshold2Controller;
  final TextEditingController threshold3Controller;
  final TextEditingController statusLabelController;
  MessageTemplate? selectedTemplate;
  List<StrappingPoint> selectedPoints;

  SettingRowData({
    this.id,
    this.parameterType = 'LEVEL',
    this.conditionType = '<',
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
  static const List<String> _defaultParameterTypes = [
    'LEVEL',
    'PRESSURE',
    'BATTERY',
    'DATA INTERVAL',
    'SOLAR',
    'DEVICE COMMUNICATE FAILED',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _simNumberController = TextEditingController();
  final _timeZoneController = TextEditingController();
  final _companyReadOnlyController = TextEditingController();
  final _siteReadOnlyController = TextEditingController();
  final _tankReadOnlyController = TextEditingController();
  final _nameFocusNode = FocusNode();

  CompanyGroup? _selectedCompanyGroup;
  List<Site> _selectedSites = [];
  List<Tank> _selectedTanks = [];
  Product? _selectedProduct;
  int _isActive = 1;

  final List<SettingRowData> _rows = [];

  List<CompanyGroup> _companyGroups = [];
  List<Site> _sites = [];
  List<Tank> _tanks = [];
  List<Product> _products = [];
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
      _companyReadOnlyController.text = s.companyName ?? 'N/A';
      _siteReadOnlyController.text = s.siteName ?? 'N/A';
      _tankReadOnlyController.text = s.tankNumber ?? 'N/A';

      _rows.add(
        SettingRowData(
          id: s.id,
          parameterType: (s.parameterType ?? 'LEVEL').toUpperCase() == 'MFACTOR'
              ? 'MFACTOR'
              : (s.parameterType ?? 'LEVEL'),
          conditionType: s.conditionType ?? '<',
          threshold1: (s.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
              ? ((s.threshold1 ?? s.threshold2)?.toInt().toString().padLeft(2, '0') ?? '00')
              : (s.threshold1?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                  '0'),
          threshold2: (s.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
              ? '00'
              : (s.threshold2?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                  '0'),
          threshold3: s.threshold_3?.toString().replaceAll(RegExp(r'\.0$'), '') ??
              '0',
          statusLabel: s.statusLabel ?? '',
        ),
      );
    } else {
      for (final param in _defaultParameterTypes) {
        _rows.add(
          SettingRowData(
            parameterType: param,
            conditionType: '<',
          ),
        );
      }
    }

    Future.microtask(() => _loadData(productNotifierProvider));
  }

  Future<void> _fetchFullTankDetails(Tank t) async {
    if (t.strappingPoints != null && t.strappingPoints!.isNotEmpty && t.channelData != null && t.channelData!.isNotEmpty) {
      return;
    }

    setState(() => _isLoadingData = true);
    try {
      final repo = ref.read(tankRepositoryProvider);
      final fullTank = await repo.getTankById(t.tankId);
      if (mounted) {
        setState(() {
          final index = _selectedTanks.indexWhere((x) => x.tankId == t.tankId);
          if (index != -1) {
            _selectedTanks[index] = fullTank;
          } else {
            _selectedTanks.add(fullTank);
          }
          final tIndex = _tanks.indexWhere((x) => x.tankId == t.tankId);
          if (tIndex != -1) {
            _tanks[tIndex] = fullTank;
          }
        });
      }
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

      final userRole = await ref.read(userRoleProvider.future);
      final isCompanyAdmin = userRole == UserRole.companyAdmin;

      int? userCompanyId;
      if (isCompanyAdmin) {
        final profileState = ref.read(profileNotifierProvider);
        if (profileState.profile == null) {
          await ref.read(profileNotifierProvider.notifier).loadProfile();
        }
        userCompanyId = ref.read(profileNotifierProvider).profile?.companyId;
      }

      try {
        final companiesList = await companyRepo.getRuleCompanies();
        if (mounted) setState(() => _companyGroups = companiesList);
      } catch (e) {
        debugPrint('Error loading companies: $e');
      }

      try {
        final siteResponse = await siteRepo.getSites(limit: 1000);
        if (mounted) setState(() => _sites = siteResponse.data);
      } catch (e) {
        debugPrint('Error loading sites: $e');
      }

      try {
        final List<Tank> tanksList = await ref.read(allTanksProvider.future);
        if (mounted) setState(() => _tanks = tanksList);
      } catch (e) {
        debugPrint('Error loading tanks: $e');
      }

      try {
        final List<MessageTemplate> templatesList = await ref.read(activeTemplatesProvider.future);
        if (mounted) setState(() => _templates = templatesList);
      } catch (e) {
        debugPrint('Error loading templates: $e');
      }

      try {
        await ref.read(productListProvider.notifier).loadProducts();
        final pState = ref.read(productListProvider);
        if (mounted) setState(() => _products = pState.products);
      } catch (e) {
        debugPrint('Error loading products: $e');
      }

      List<Setting> matchedRules = [];
      if (widget.initialSetting != null) {
        final s = widget.initialSetting!;
        try {
          final settingResponse = await ref.read(settingRepositoryProvider).getSettings(
            tankId: s.tankId,
            plantId: s.siteId,
            name: s.tankId == null ? s.name : null,
            limit: 100,
          );
          if (s.tankId != null) {
            matchedRules = settingResponse.data;
          } else {
            matchedRules = settingResponse.data
                .where((r) => r.name.trim().toLowerCase() == s.name.trim().toLowerCase())
                .toList();
          }
        } catch (e) {
          debugPrint('Error fetching bulk rules in loadData: $e');
        }
      } else if (widget.preselectedTank != null) {
        final t = widget.preselectedTank!;
        try {
          final settingResponse = await ref.read(settingRepositoryProvider).getSettings(
            tankId: t.tankId,
            limit: 100,
          );
          matchedRules = settingResponse.data;
        } catch (e) {
          debugPrint('Error fetching preselected tank rules in loadData: $e');
        }
      }

      setState(() {
        if (widget.initialSetting != null) {
          final s = widget.initialSetting!;
          _selectedCompanyGroup = _companyGroups
              .where((g) => g.addresses.any((a) => a.companyId == s.companyId))
              .firstOrNull;

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
            final site = _sites.where((p) => p.id == s.siteId).firstOrNull;
            if (site != null) _selectedSites = [site];
          }

          if (s.tankId != null) {
            final tank = _tanks
                .where((t) => t.tankId == s.tankId)
                .firstOrNull;
            if (tank != null) _selectedTanks = [tank];
          }

          if (s.productId != null) {
            _selectedProduct = _products
                .where((p) => p.id == s.productId)
                .firstOrNull;
          } else if (_selectedTanks.isNotEmpty && _selectedTanks.first.productId != null &&
              _selectedTanks.first.productId != 0) {
            _selectedProduct = _products
                .where((p) => p.id == _selectedTanks.first.productId)
                .firstOrNull;
          }

          if (matchedRules.isNotEmpty) {
            _rows.clear();
            for (final r in matchedRules) {
              final rowData = SettingRowData(
                id: r.id,
                parameterType: (r.parameterType ?? 'LEVEL').toUpperCase() == 'MFACTOR'
                    ? 'MFACTOR'
                    : (r.parameterType ?? 'LEVEL'),
                conditionType: r.conditionType ?? '<',
                threshold1: (r.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
                    ? ((r.threshold1 ?? r.threshold2)?.toInt().toString().padLeft(2, '0') ?? '00')
                    : (r.threshold1?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                        '0'),
                threshold2: (r.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
                    ? '00'
                    : (r.threshold2?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                        '0'),
                threshold3: r.threshold_3?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                    '0',
                statusLabel: r.statusLabel ?? '',
              );

              if (r.messageTemplateId != null) {
                rowData.selectedTemplate = _templates
                    .where((t) => t.id == r.messageTemplateId)
                    .firstOrNull;
              }
              _rows.add(rowData);
            }

            // Append default/empty rows for any default parameters not present in loaded settings
            final loadedTypes = _rows.map((row) => row.parameterType.toUpperCase().trim()).toSet();
            for (final param in _defaultParameterTypes) {
              if (!loadedTypes.contains(param.toUpperCase().trim())) {
                _rows.add(SettingRowData(
                  parameterType: param,
                  conditionType: '<',
                ));
              }
            }

            _nameController.text = s.name;
            _descriptionController.text = s.description ?? '';
            _isActive = s.isActive;
          } else {
            if (s.messageTemplateId != null && _rows.isNotEmpty) {
              final targetRow = _rows.firstWhere(
                (r) => r.parameterType.toUpperCase().trim() == (s.parameterType ?? 'LEVEL').toUpperCase().trim(),
                orElse: () => _rows[0],
              );
              targetRow.selectedTemplate = _templates
                  .where((t) => t.id == s.messageTemplateId)
                  .firstOrNull;
            }
          }

          _deviceIdController.text =
              s.deviceId ?? _selectedTanks.firstOrNull?.deviceId ?? '';
          _simNumberController.text =
              s.simNumber ?? _selectedTanks.firstOrNull?.simNumber ?? '';
          _timeZoneController.text =
              s.timeZone ?? _selectedTanks.firstOrNull?.timeZone ?? '';

          if (_selectedTanks.isNotEmpty) {
            _fetchFullTankDetails(_selectedTanks.first);
          }
        } else if (widget.preselectedTank != null) {
          final t = widget.preselectedTank!;
          final tank = _tanks.where((x) => x.tankId == t.tankId).firstOrNull ?? t;
          _selectedTanks = [tank];

          final site = _sites.where((s) => s.id == tank.siteId).firstOrNull;
          if (site != null) {
            _selectedSites = [site];
          }

          _selectedCompanyGroup = _companyGroups
              .where((g) => g.addresses.any((a) => a.companyId == tank.companyId))
              .firstOrNull;

          _deviceIdController.text = tank.deviceId ?? '';
          _simNumberController.text = tank.simNumber ?? '';
          _timeZoneController.text = tank.timeZone ?? '';

          if (matchedRules.isNotEmpty) {
            _rows.clear();
            for (final r in matchedRules) {
              final rowData = SettingRowData(
                id: r.id,
                parameterType: (r.parameterType ?? 'LEVEL').toUpperCase() == 'MFACTOR'
                    ? 'MFACTOR'
                    : (r.parameterType ?? 'LEVEL'),
                conditionType: r.conditionType ?? '<',
                threshold1: (r.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
                    ? ((r.threshold1 ?? r.threshold2)?.toInt().toString().padLeft(2, '0') ?? '00')
                    : (r.threshold1?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                        '0'),
                threshold2: (r.parameterType?.toUpperCase().trim() == 'DATA INTERVAL')
                    ? '00'
                    : (r.threshold2?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                        '0'),
                threshold3: r.threshold_3?.toString().replaceAll(RegExp(r'\.0$'), '') ??
                    '0',
                statusLabel: r.statusLabel ?? '',
              );

              if (r.messageTemplateId != null) {
                rowData.selectedTemplate = _templates
                    .where((t) => t.id == r.messageTemplateId)
                    .firstOrNull;
              }
              _rows.add(rowData);
            }

            // Append default/empty rows for any default parameters not present in loaded settings
            final loadedTypes = _rows.map((row) => row.parameterType.toUpperCase().trim()).toSet();
            for (final param in _defaultParameterTypes) {
              if (!loadedTypes.contains(param.toUpperCase().trim())) {
                _rows.add(SettingRowData(
                  parameterType: param,
                  conditionType: '<',
                ));
              }
            }

            final systemRuleNames = {
              'data interval',
              'device communicate failed',
              'device communicate',
              'solar',
              'battery',
              'pressure',
              'level'
            };
            String groupName = matchedRules.first.name;
            String? groupDesc = matchedRules.first.description;
            int groupActive = matchedRules.first.isActive;
            for (final r in matchedRules) {
              final nameLower = r.name.trim().toLowerCase();
              if (!systemRuleNames.contains(nameLower)) {
                groupName = r.name;
                groupDesc = r.description;
                groupActive = r.isActive;
                break;
              }
            }
            _nameController.text = groupName;
            _descriptionController.text = groupDesc ?? '';
            _isActive = groupActive;
          }

          _fetchFullTankDetails(tank);
        } else {
          if (isCompanyAdmin && userCompanyId != null) {
            _selectedCompanyGroup = _companyGroups
                .where((g) => g.addresses.any((a) => a.companyId == userCompanyId))
                .firstOrNull;
          }
          if (_tanks.length == 1) {
            _selectedTanks = [_tanks[0]];
            final s = _sites
                .where((p) => p.id == _selectedTanks[0].siteId)
                .firstOrNull;
            if (s != null) _selectedSites = [s];
            _selectedCompanyGroup = _companyGroups
                .where(
                  (g) => g.addresses.any(
                    (a) => a.companyId == _selectedTanks[0].companyId,
                  ),
                )
                .firstOrNull;
            _deviceIdController.text = _selectedTanks.firstOrNull?.deviceId ?? '';
            _simNumberController.text = _selectedTanks.firstOrNull?.simNumber ?? '';
            _timeZoneController.text = _selectedTanks.firstOrNull?.timeZone ?? '';
            _fetchFullTankDetails(_selectedTanks[0]);
          }
        }

        if (widget.initialSetting != null) {
          final s = widget.initialSetting!;
          _companyReadOnlyController.text = () {
            final cg = _selectedCompanyGroup;
            if (cg == null) return s.companyName ?? 'N/A';
            final name = cg.name.trim().isNotEmpty ? cg.name.trim() : '(Unnamed Company)';
            final org = cg.organizationCode;
            return (org != null && org.trim().isNotEmpty) ? "$name ($org)" : name;
          }();
          _siteReadOnlyController.text = _selectedSites.isNotEmpty
              ? _selectedSites.map((site) {
                  final loc = site.siteLocation;
                  return loc.isNotEmpty ? "${site.name} ($loc)" : site.name;
                }).join(', ')
              : (s.siteName ?? 'N/A');
          _tankReadOnlyController.text = _selectedTanks.isNotEmpty
              ? _selectedTanks.map((t) => t.tankNumber).join(', ')
              : (s.tankNumber ?? 'N/A');
        } else if (isCompanyAdmin && _selectedCompanyGroup != null) {
          _companyReadOnlyController.text = () {
            final cg = _selectedCompanyGroup!;
            final name = cg.name.trim().isNotEmpty ? cg.name.trim() : '(Unnamed Company)';
            final org = cg.organizationCode;
            return (org != null && org.trim().isNotEmpty) ? "$name ($org)" : name;
          }();
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
      if (_selectedSites.isEmpty) {
        if (!silent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Site is required')));
        }
        return false;
      }
      if (_selectedTanks.isEmpty) {
        if (!silent) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tank is required')));
        }
        return false;
      }
    }

    final companyId = _selectedCompanyGroup!.addresses.first.companyId;
    final notifier = ref.read(settingProvider.notifier);

    // Filter out rows that do not have a threshold value configured
    final activeRows = _rows.where((row) {
      final param = row.parameterType.toUpperCase().trim();
      if (param == 'CHART DATA') {
        return row.selectedPoints.isNotEmpty;
      }
      return row.threshold1Controller.text.trim().isNotEmpty;
    }).toList();

    if (activeRows.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please configure at least one rule parameter value.'),
          ),
        );
      }
      return false;
    }

    final List<Map<String, dynamic>> rowsData = activeRows.map((row) {
      final isDataInterval =
          row.parameterType.toUpperCase().trim() == 'DATA INTERVAL';
      return {
        if (row.id != null) 'id': row.id,
        'parameter_type': row.parameterType,
        'condition_type': row.conditionType,
        'threshold_1': double.tryParse(row.threshold1Controller.text.trim()),
        'threshold_2': isDataInterval
            ? 0.0
            : double.tryParse(row.threshold2Controller.text.trim()),
        'threshold_3': double.tryParse(row.threshold3Controller.text.trim()),
        'status_label': row.statusLabelController.text.trim().isEmpty
            ? null
            : row.statusLabelController.text.trim(),
        'message_template_id': row.selectedTemplate?.id,
      };
    }).toList();

    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'company_id': companyId,
      'plant_ids': _selectedSites.map((s) => s.id).toList(),
      'tank_ids': _selectedTanks.map((t) => t.tankId).toList(),
      'product_id': _selectedProduct?.id,
      'rows': rowsData,
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
    if (widget.initialSetting != null) {
      success = await notifier.updateSetting(widget.initialSetting!.id, data);
    } else {
      success = await notifier.createSetting(data);
    }

    if (mounted) {
      setState(() => _isLoadingData = false);
      if (success) {
        if (!silent) {
          // Always try to send to device after a successful DB save
          final hasDevice = _deviceIdController.text.trim().isNotEmpty ||
              _selectedTanks.any((t) => t.deviceId != null && t.deviceId!.isNotEmpty);

          if (hasDevice) {
            await _sendToDevice(skipSave: true);
          } else {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rule(s) saved successfully')),
              );
            }
          }
        }
      }
    }
    return success;
  }

  Future<void> _sendToDevice({bool skipSave = false}) async {
    final userRole = ref.read(userRoleProvider).asData?.value;
    final isSuperOrCompany =
        userRole == UserRole.superAdmin || userRole == UserRole.companyAdmin;

    if (isSuperOrCompany) {
      if (_selectedSites.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Site is required')));
        return;
      }
      if (_selectedTanks.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tank is required')));
        return;
      }
    }

    // Collect device IDs from selected tanks
    final deviceIds = _selectedTanks
        .map((t) => t.deviceId)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    // Fallback to manually entered device ID if tanks don't have one
    final manualDeviceId = _deviceIdController.text.trim();
    if (deviceIds.isEmpty && manualDeviceId.isNotEmpty) {
      deviceIds.add(manualDeviceId);
    }

    if (deviceIds.isEmpty) {
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
      final simNumber = _simNumberController.text.trim().isEmpty
          ? 'N/A'
          : _simNumberController.text.trim();
      final deviceIdPlaceholder = deviceIds.first;

      // Save first if not already saved
      if (!skipSave) {
        final saveSuccess = await _save(silent: true);
        if (!saveSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save rules before sending to device'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Send MQTT command for each row
      final activeRows = _rows.where((row) {
        final param = row.parameterType.toUpperCase().trim();
        if (param == 'CHART DATA') {
          return row.selectedPoints.isNotEmpty;
        }
        return row.threshold1Controller.text.trim().isNotEmpty;
      }).toList();

      if (activeRows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active configurations to send to device')),
          );
        }
        return;
      }

      final List<String> sentParams = [];
      final List<String> failedParams = [];

      for (final row in activeRows) {
        final param = row.parameterType.toUpperCase().trim();
        final cond = row.conditionType;
        final thresh1 = row.threshold1Controller.text.trim();
        final thresh2 = row.threshold2Controller.text.trim();
        final thresh3 = row.threshold3Controller.text.trim();

        String? payload;

        if (param == 'LEVEL') {
          payload = 'ReOrderLevel,$thresh1';
        } else if (param == 'CAL TANK') {
          final val1 = ((double.tryParse(thresh1) ?? 0) * 100000).toInt();
          final val2 = ((double.tryParse(thresh2) ?? 0) * 100000).toInt();
          payload = 'CALTANK,1,$val1,$val2';
        } else if (param == 'CAL KILO LITER') {
          payload = 'CALLTRS,1,$thresh1,$thresh2';
        } else if (param == 'SETCALBAR' || param == 'SETBAR') {
          payload = 'SETCALIBBAR,1,$thresh1';
        } else if (param == 'MFACTOR') {
          payload = 'MRATIO,1,$thresh1,$thresh2,$thresh3';
        } else if (param == 'SENSOR' || param == 'SENSOR RATING') {
          final productCode = _selectedProduct?.productCode ?? 'N/A';
          final tonnes = (_selectedTanks.isNotEmpty
                  ? (_selectedTanks.first.tonnes ?? 0.0)
                  : 0.0)
              .toStringAsFixed(2);
          payload = 'SENSORRATING,1,$thresh1,$productCode,$thresh2,$tonnes,0';
        } else if (param == 'DATA INTERVAL') {
          final mins = int.tryParse(thresh1) ?? 0;
          final minsStr = mins.toString().padLeft(4, '0');
          payload = 'DATAINTERVAL,$minsStr';
        } else if (param == 'BATTERY') {
          payload = 'BATVOLTCAL,1,$thresh1';
        } else if (param == 'SOLAR' || param == 'SOLOR') {
          payload = 'SOLARVOLTCAL,1,$thresh1';
        } else if (param == 'PRESSURE') {
          payload = 'PRESSURE,$cond,$thresh1,$thresh2';
        } else if (param == 'DEVICE COMMUNICATE FAILED') {
          payload = 'COMFAILED,$thresh1';
        } else if (param == 'CHART DATA') {
          final pointsData = row.selectedPoints
              .map((p) => '${p.levelMm.toInt()},${p.volumeM3.toInt()}')
              .join(',');
          payload = '{"\"chartdata\"",$pointsData,9999,9999}';
        } else {
          payload =
              '$productName,$scmM3,$specificGravity,$param,$cond,$thresh1,$thresh2,$thresh3,N/A,$deviceIdPlaceholder,$simNumber,$param';
        }

        try {
          final response = await apiClient.post(
            '/mqtt/send-command',
            data: {
              'deviceIds': deviceIds,
              'sms': payload,
              'parameter_type': param,
              'status_label': row.statusLabelController.text.trim(),
            },
          );
          if (response.statusCode == 200) {
            sentParams.add(param);
          } else {
            failedParams.add(param);
          }
        } catch (_) {
          failedParams.add(param);
        }
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        final String message;
        final Color bg;
        if (failedParams.isEmpty) {
          message =
              'Saved & sent to device: ${sentParams.join(', ')}';
          bg = Colors.green;
        } else if (sentParams.isNotEmpty) {
          message =
              'Sent: ${sentParams.join(', ')}. Failed: ${failedParams.join(', ')}';
          bg = Colors.orange;
        } else {
          message = 'Saved to DB. Failed to send: ${failedParams.join(', ')}';
          bg = Colors.orange;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: bg),
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
      filteredSites = _sites.where((p) {
        final belongsToCompany = companyIds.contains(p.companyId);
        final hasTanks = _tanks.any((t) => t.siteId == p.id);
        return belongsToCompany && hasTanks;
      }).toList();
    }

    final companyIds = _selectedCompanyGroup?.addresses
            .map((a) => a.companyId ?? 0)
            .toList() ??
        <int>[];
    final tanksForSite = (_selectedSites.isNotEmpty
        ? _tanks.where((t) => _selectedSites.any((s) => s.id == t.siteId)).toList()
        : (_selectedCompanyGroup != null
            ? _tanks.where((t) => companyIds.contains(t.companyId)).toList()
            : <Tank>[]))
      ..sort((a, b) => (a.siteName ?? '').compareTo(b.siteName ?? ''));

    final bool isEditMode = widget.initialSetting != null;

    final roleAsync = ref.watch(userRoleProvider);
    final isCustomer = roleAsync.when(
      data: (role) => role == UserRole.customer,
      loading: () => false,
      error: (_, __) => false,
    );

    final canSendToDevice = roleAsync.when(
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

    final isCompanyAdmin = roleAsync.when(
      data: (role) => role == UserRole.companyAdmin,
      loading: () => false,
      error: (_, __) => false,
    );

    final displayParams = List<String>.from(_defaultParameterTypes);
    for (final row in _rows) {
      final normalizedParam = row.parameterType.toUpperCase().trim();
      if (!displayParams.any((p) => p.toUpperCase().trim() == normalizedParam)) {
        displayParams.add(row.parameterType);
      }
    }

    final enabledChannels = <String>{};
    bool hasChannelData = false;
    for (final tank in _selectedTanks) {
      if (tank.channelData != null && tank.channelData!.isNotEmpty) {
        hasChannelData = true;
        for (final channel in tank.channelData!) {
          if (channel.enabled && channel.type != null) {
            enabledChannels.add(channel.type!.toUpperCase().trim());
          }
        }
      }
    }

    if (hasChannelData) {
      displayParams.removeWhere((param) {
        final upperParam = param.toUpperCase().trim();
        if (upperParam == 'LEVEL' || upperParam == 'PRESSURE') {
          final isEnabled = enabledChannels.contains(upperParam);
          final hasExistingRow = _rows.any((row) {
            final rowParam = row.parameterType.toUpperCase().trim();
            final hasValue = row.threshold1Controller.text.trim().isNotEmpty;
            return rowParam == upperParam && hasValue;
          });
          return !isEnabled && !hasExistingRow;
        }
        return false;
      });
    }

    final bool hasActiveDataInterval = _rows.any((r) =>
        r.parameterType.toUpperCase().trim() == 'DATA INTERVAL' &&
        r.threshold1Controller.text.trim().isNotEmpty);

    final bool hasActiveDeviceCommFailed = _rows.any((r) =>
        r.parameterType.toUpperCase().trim() == 'DEVICE COMMUNICATE FAILED' &&
        r.threshold1Controller.text.trim().isNotEmpty);

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
                child: _isLoadingData && _companyGroups.isEmpty
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
                                isEditMode
                                    ? AppTextField(
                                        controller: _nameController,
                                        readOnly: true,
                                        hint: isCustomer
                                            ? 'e.g. Critical Tank Level Low'
                                            : 'e.g. High Pressure Warning',
                                      )
                                    : RawAutocomplete<SettingAutocompleteInfo>(
                                        textEditingController: _nameController,
                                        focusNode: _nameFocusNode,
                                        optionsBuilder: (TextEditingValue textEditingValue) async {
                                          if (textEditingValue.text.isEmpty) {
                                            return const Iterable<SettingAutocompleteInfo>.empty();
                                          }
                                          return await ref.read(settingProvider.notifier).searchSettings(textEditingValue.text);
                                        },
                                        displayStringForOption: (option) => option.name,
                                        onSelected: (selection) {
                                          _nameController.text = selection.name;
                                        },
                                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                          return AppTextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            hint: isCustomer
                                                ? 'e.g. Critical Tank Level Low'
                                                : 'e.g. High Pressure Warning',
                                          );
                                        },
                                        optionsViewBuilder: (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 4.0,
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                width: 670,
                                                constraints: const BoxConstraints(maxHeight: 250),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  itemCount: options.length,
                                                  itemBuilder: (context, index) {
                                                    final option = options.elementAt(index);
                                                    return ListTile(
                                                      title: Text(
                                                        option.name,
                                                        style: GoogleFonts.inter(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        option.siteName ?? '—',
                                                        style: GoogleFonts.inter(fontSize: 12),
                                                      ),
                                                      onTap: () => onSelected(option),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
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
                                        AppTextField(
                                          readOnly: true,
                                          controller: _tankReadOnlyController,
                                          hint: 'Tank Name',
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
                                        (isEditMode || isCompanyAdmin)
                                            ? AppTextField(
                                                readOnly: true,
                                                controller: _companyReadOnlyController,
                                                hint: 'Company Name',
                                              )
                                            : AppDropdown<CompanyGroup>(
                                                value: _selectedCompanyGroup,
                                                items: _companyGroups,
                                                hint: 'Select Company',
                                                itemLabel: (cg) {
                                                  final name = cg.name.trim().isNotEmpty ? cg.name.trim() : '(Unnamed Company)';
                                                  final org = cg.organizationCode;
                                                  return (org != null && org.trim().isNotEmpty) ? "$name ($org)" : name;
                                                },
                                                onChanged: (cg) => setState(() {
                                                  _selectedCompanyGroup = cg;
                                                  _selectedSites = [];
                                                  _selectedTanks = [];
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
                                        isEditMode
                                            ? AppTextField(
                                                readOnly: true,
                                                controller: _siteReadOnlyController,
                                                hint: 'Site Name',
                                              )
                                            : AppMultiSelectDropdown<Site>(
                                                selectedItems: _selectedSites,
                                                items: filteredSites,
                                                hint: _selectedCompanyGroup == null
                                                    ? 'Select Company First'
                                                    : 'Select Site(s)',
                                                itemLabel: (s) {
                                                  final loc = s.siteLocation;
                                                  return loc.isNotEmpty ? "${s.name} ($loc)" : s.name;
                                                },
                                                enabled: _selectedCompanyGroup != null,
                                                onChanged: (sites) => setState(() {
                                                  _selectedSites = sites;
                                                  _selectedTanks = [];
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
                                        AppMultiSelectDropdown<Tank>(
                                          selectedItems: _selectedTanks,
                                          items: tanksForSite,
                                          hint: _selectedSites.isEmpty
                                              ? 'Select Site(s) First'
                                              : 'Select Tank(s)',
                                          itemLabel: (t) {
                                            final site = t.siteName ?? 'Unknown Site';
                                            final dev = t.deviceId;
                                            return "$site - ${t.tankNumber}${dev != null && dev.isNotEmpty ? ' ($dev)' : ''}";
                                          },
                                          enabled: _selectedSites.isNotEmpty,
                                          onChanged: (tanks) {
                                            setState(() {
                                              _selectedTanks = tanks;
                                              if (tanks.isNotEmpty) {
                                                final t = tanks.first;
                                                _deviceIdController.text = t.deviceId ?? '';
                                                _simNumberController.text = t.simNumber ?? '';
                                                _timeZoneController.text = t.timeZone ?? '';
                                                if (t.productId != null && t.productId != 0) {
                                                  _selectedProduct = _products.where((p) => p.id == t.productId).firstOrNull;
                                                }
                                                _fetchFullTankDetails(t);
                                              }
                                            });
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
                              ...displayParams.map((param) {
                                final paramRows = _rows
                                    .where((row) =>
                                        row.parameterType.toUpperCase().trim() ==
                                        param.toUpperCase().trim())
                                    .toList();
                                return _buildParamSection(
                                    param, paramRows, isCustomer);
                              }).toList(),
                              const SizedBox(height: 32),
                              _buildStatusSection(),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  if (canSendToDevice && !isEditMode && hasActiveDataInterval) ...[
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
                                                isEditMode &&
                                                hasActiveDataInterval)
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
                                                    ? (hasActiveDeviceCommFailed
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

  bool _showThreshold2(SettingRowData row) {
    return row.conditionType == 'BETWEEN' ||
        [
          'CAL TANK',
          'CAL KILO LITER',
          'SENSOR',
          'SENSOR RATING',
          'MFACTOR',
        ].contains(row.parameterType.toUpperCase().trim());
  }

  bool _showThreshold3(SettingRowData row) {
    return row.parameterType.toUpperCase().trim() == 'MFACTOR';
  }

  String _getThresholdLabel(SettingRowData row) {
    final param = row.parameterType.toUpperCase().trim();
    if (param == 'SENSOR' || param == 'SENSOR RATING') {
      return 'SENSOR RATING';
    }
    if (param == 'BATTERY' || param == 'SOLAR') {
      return 'VOLTAGE';
    }
    if (param == 'DATA INTERVAL' || param == 'DEVICE COMMUNICATE FAILED') {
      return 'Minutes';
    }
    if ([
      'CAL TANK',
      'CAL KILO LITER',
      'MFACTOR',
      'SETBAR',
      'SETCALBAR',
    ].contains(param)) {
      return '${row.parameterType} 1';
    }
    if (param == 'CHART DATA') {
      return 'Field 1';
    }
    return row.conditionType == 'BETWEEN' ? 'MIN THRESHOLD' : 'THRESHOLD VALUE';
  }

  String _getThreshold2Label(SettingRowData row) {
    final param = row.parameterType.toUpperCase().trim();
    if (param == 'SENSOR' || param == 'SENSOR RATING') {
      return 'CUBIC METER';
    }
    if (param == 'DATA INTERVAL') {
      return 'Seconds';
    }
    if ([
      'CAL TANK',
      'CAL KILO LITER',
      'MFACTOR',
    ].contains(param)) {
      return '${row.parameterType} 2';
    }
    return 'MAX THRESHOLD';
  }

  Widget _buildThresholdField(SettingRowData row) {
    if (row.parameterType.toUpperCase().trim() == 'CHART DATA') {
      return AppMultiSelectDropdown<StrappingPoint>(
        selectedItems: row.selectedPoints,
        items: _selectedTanks.firstOrNull?.strappingPoints ?? [],
        hint: _selectedTanks.isEmpty
            ? 'Select Tank First'
            : (_selectedTanks.first.strappingPoints == null ||
                    _selectedTanks.first.strappingPoints!.isEmpty)
                ? 'No Points Available'
                : 'Select Point(s)',
        itemLabel: (p) => 'L: ${p.levelMm} | V: ${p.volumeM3}',
        onChanged: (list) {
          setState(() {
            row.selectedPoints = list;
            row.threshold1Controller.text = list.map((p) => p.levelMm).join(',');
            row.threshold2Controller.text = list.map((p) => p.volumeM3).join(',');
          });
        },
      );
    }
    return AppTextField(
      controller: row.threshold1Controller,
      hint: 'Value',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildThreshold2Field(SettingRowData row) {
    return AppTextField(
      controller: row.threshold2Controller,
      hint: 'Value',
      readOnly: row.parameterType.toUpperCase().trim() == 'CHART DATA',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildThreshold3Field(SettingRowData row) {
    return AppTextField(
      controller: row.threshold3Controller,
      hint: 'Value',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildStatusLabelAndTemplate(SettingRowData row, bool isCustomer) {
    final showStatusLabel = ![
      'CAL TANK',
      'CAL KILO LITER',
      'SENSOR',
      'SENSOR RATING',
      'MFACTOR',
      'SETBAR',
      'SETCALBAR',
      'CHART DATA',
      'DATA INTERVAL',
    ].contains(row.parameterType.toUpperCase().trim());

    final showMessageTemplate = !isCustomer && ![
      'CAL TANK',
      'CAL KILO LITER',
      'SENSOR',
      'SENSOR RATING',
      'MFACTOR',
      'SETBAR',
      'SETCALBAR',
      'CHART DATA',
      'DATA INTERVAL',
      'TEMPERATURE',
      'FLOW',
    ].contains(row.parameterType.toUpperCase().trim());

    if (!showStatusLabel && !showMessageTemplate) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (showStatusLabel)
            Expanded(
              child: _buildLabelField(
                'STATUS LABEL (UI DISPLAY)',
                ([
                  'LEVEL',
                  'BATTERY',
                  'PRESSURE',
                  'SOLAR'
                ].contains(row.parameterType.toUpperCase().trim()))
                    ? AppDropdown<String>(
                        value: () {
                          const allowed = [
                            'ReOrder',
                            'Critical',
                            'Low',
                            'High',
                          ];
                          final current = row.statusLabelController.text;
                          if (allowed.contains(current)) return current;
                          final upper = current.toUpperCase();
                          if (upper == 'REORDER') return 'ReOrder';
                          if (upper == 'CRITICAL') return 'Critical';
                          if (upper.contains('LOW')) return 'Low';
                          if (upper.contains('HIGH')) return 'High';
                          return null;
                        }(),
                        items: ([
                          'BATTERY',
                          'PRESSURE',
                          'SOLAR'
                        ].contains(row.parameterType.toUpperCase().trim()))
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
                          () => row.statusLabelController.text = v ?? '',
                        ),
                      )
                    : AppTextField(
                        controller: row.statusLabelController,
                        hint: 'e.g. LOW LEVEL',
                      ),
              ),
            ),
          if (showStatusLabel && showMessageTemplate)
            const SizedBox(width: 16),
          if (showMessageTemplate)
            Expanded(
              child: _buildLabelField(
                'MESSAGE TEMPLATE TO TRIGGER',
                AppDropdown<MessageTemplate>(
                  value: row.selectedTemplate,
                  items: _templates,
                  hint: 'Select Template',
                  itemLabel: (t) => t.name,
                  onChanged: (t) => setState(
                    () => row.selectedTemplate = t,
                  ),
                ),
              ),
            ),
          if (showStatusLabel != showMessageTemplate)
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildRowContainer(SettingRowData row, List<SettingRowData> paramRows, int index, bool isCustomer) {
    final bool showCondition = ![
      'CAL TANK',
      'CAL KILO LITER',
      'SENSOR',
      'SENSOR RATING',
      'MFACTOR',
      'SETBAR',
      'SETCALBAR',
      'CHART DATA',
      'DATA INTERVAL',
    ].contains(row.parameterType.toUpperCase().trim());

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (paramRows.length > 1)
            Align(
              alignment: Alignment.topRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    row.dispose();
                    _rows.remove(row);
                  });
                },
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: Colors.red,
                ),
                label: Text(
                  'Remove Condition',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          if (paramRows.length > 1) const SizedBox(height: 8),
          
          if (showCondition)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      onChanged: (v) => setState(() => row.conditionType = v!),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildLabelField(
                    _getThresholdLabel(row),
                    _buildThresholdField(row),
                  ),
                ),
                if (_showThreshold2(row)) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildLabelField(
                      _getThreshold2Label(row),
                      _buildThreshold2Field(row),
                    ),
                  ),
                ],
                if (_showThreshold3(row)) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildLabelField(
                      '${row.parameterType} 3',
                      _buildThreshold3Field(row),
                    ),
                  ),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildLabelField(
                    _getThresholdLabel(row),
                    _buildThresholdField(row),
                  ),
                ),
                if (_showThreshold2(row)) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLabelField(
                      _getThreshold2Label(row),
                      _buildThreshold2Field(row),
                    ),
                  ),
                ],
                if (_showThreshold3(row)) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLabelField(
                      '${row.parameterType} 3',
                      _buildThreshold3Field(row),
                    ),
                  ),
                ],
              ],
            ),
            
          _buildStatusLabelAndTemplate(row, isCustomer),
        ],
      ),
    );
  }

  Widget _buildParamSection(String param, List<SettingRowData> paramRows, bool isCustomer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${param.toUpperCase()} CONFIGURATION',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141E7A),
              letterSpacing: 1.1,
            ),
          ),
        ),
        ...paramRows.asMap().entries.map((entry) {
          return _buildRowContainer(entry.value, paramRows, entry.key, isCustomer);
        }).toList(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _rows.add(SettingRowData(
              parameterType: param,
              conditionType: '<',
            ));
          }),
          icon: const Icon(
            Icons.add_circle_outline,
            color: Color(0xFF141E7A),
            size: 16,
          ),
          label: Text(
            'ADD ANOTHER CONFIGURATION',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: const Color(0xFF141E7A),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF141E7A)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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
    _companyReadOnlyController.dispose();
    _siteReadOnlyController.dispose();
    _tankReadOnlyController.dispose();
    _nameFocusNode.dispose();
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}
