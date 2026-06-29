import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../site/presentation/model/site_model.dart';
import '../../data/model/tank_model.dart';
import '../../data/model/tank_rule_model.dart';
import '../controller/tank_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../user/presentation/controller/user_provider.dart';
import '../../../user/presentation/model/user_model.dart';
import '../../../tank_dimension/data/tank_dimension_model.dart';
import '../../../tank_dimension/provider/tank_dimension_provider.dart';

class AddTankModal extends ConsumerStatefulWidget {
  final Tank? tank;
  final VoidCallback? onSuccess;
  const AddTankModal({super.key, this.tank, this.onSuccess});

  @override
  ConsumerState<AddTankModal> createState() => _AddTankModalState();
}

class _AddTankModalState extends ConsumerState<AddTankModal> {
  final _tankNumberController = TextEditingController();
  final _tonnesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _siteAutocompleteController = TextEditingController();
  final _companyAutocompleteController = TextEditingController();
  final _companyFocusNode = FocusNode();

  SiteAutocompleteInfo? _selectedSite;
  CompanyAutocomplete? _selectedCompany;
  List<TankProduct> _products = [];
  bool _isLoadingDropdowns = false;

  List<TankRuleModel> _tankRules = [];
  TankRuleModel? _selectedRule;
  TankDimension? _selectedDimension;

  dynamic _selectedUnit;
  dynamic _selectedTankType;
  TankProduct? _selectedProduct;
  int _status = 1;

  late List<Map<String, dynamic>> _channels;
  late List<bool> _channelEnabled;

  @override
  void initState() {
    super.initState();
    if (widget.tank != null) {
      final tank = widget.tank!;
      _tankNumberController.text = tank.tankNumber;
      _tonnesController.text = tank.tonnes?.toString() ?? '';
      _descriptionController.text = tank.description ?? '';
      _siteAutocompleteController.text = tank.siteName ?? '';
      _status = tank.status;
      if (tank.companyId != null && tank.companyName != null) {
        _selectedCompany = CompanyAutocomplete(
          id: tank.companyId!,
          name: tank.companyName!,
        );
        _companyAutocompleteController.text = tank.companyName!;
      }
    } else {
      _selectedCompany = CompanyAutocomplete(
        id: 216,
        name: 'Air Water',
      );
      _companyAutocompleteController.text = 'Air Water';
    }

    _loadDropdownData();
    _initializeChannels();
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoadingDropdowns = true);

    Map<String, dynamic> data = {};
    List<TankProduct> products = [];
    List<TankRuleModel> rules = [];

    try {
      final results = await Future.wait<dynamic>([
        ref.read(tankNotifierProvider.notifier).getDropdowns().catchError((e) {
          debugPrint('Error loading dropdowns metadata: $e');
          return <String, dynamic>{};
        }),
        ref.read(tankNotifierProvider.notifier).getProducts().catchError((e) {
          debugPrint('Error loading products list: $e');
          return <TankProduct>[];
        }),
        ref.read(tankRepositoryProvider).getAllTankRules().catchError((e) {
          debugPrint('Error loading all tank rules: $e');
          return <TankRuleModel>[];
        }),
        ref.read(tankDimensionNotifierProvider.notifier).loadTankDimensions().catchError((e) {
          debugPrint('Error loading tank dimensions in modal: $e');
          return null;
        }),
      ]);

      if (results[0] is Map<String, dynamic>) {
        data = results[0] as Map<String, dynamic>;
      }

      if (results[1] is List) {
        products = List<TankProduct>.from(results[1] as Iterable);
      }

      if (results[2] is List) {
        rules = List<TankRuleModel>.from(results[2] as Iterable);
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading dropdowns in Future.wait: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    setState(() {
      _products = products;
      _tankRules = rules;

      if (widget.tank != null) {
        // UNIT
        final units = (data['units'] as List?) ?? [];
        final unitMatches =
        units.where((u) => u['id'] == widget.tank!.unitId);

        _selectedUnit =
        unitMatches.isNotEmpty ? unitMatches.first : null;

        // TANK TYPE
        final tankTypes = (data['tank_types'] as List?) ?? [];
        final tankTypeMatches =
        tankTypes.where((tt) => tt['id'] == widget.tank!.tankTypeId);

        _selectedTankType =
        tankTypeMatches.isNotEmpty ? tankTypeMatches.first : null;

        // PRODUCT
        final foundProducts =
        products.where((p) => p.productId == widget.tank!.productId);

        _selectedProduct =
        foundProducts.isNotEmpty ? foundProducts.first : null;

        // RULE
        final foundRule =
        rules.where((tr) => tr.id == widget.tank!.ruleId);

        _selectedRule =
        foundRule.isNotEmpty ? foundRule.first : null;

        // TANK DIMENSION
        final dims = ref.read(tankDimensionNotifierProvider).tankDimensions;
        final dimMatches = dims.where((d) => d.id == widget.tank!.tankDimension);
        _selectedDimension = dimMatches.isNotEmpty ? dimMatches.first : null;
      }
      _isLoadingDropdowns = false;
    });
  }


  void _initializeChannels() {
    final apiChannels = widget.tank?.channelData ?? [];

    if (apiChannels.isNotEmpty) {
      _channels = apiChannels.map((channel) {
        return {
          'type': channel.type ?? '',
          'min': channel.min ?? 0,
          'max': channel.max ?? 0,
          'units': channel.units ?? '',
          'enabled': channel.enabled ?? true,
        };
      }).toList();
    } else {
      _channels = [
        {
          'type': 'Level',
          'min': 0,
          'max': 0,
          'units': '% Full',
          'enabled': true,
        },
        {
          'type': 'Pressure',
          'min': 0,
          'max': 0,
          'units': 'Bar',
          'enabled': true,
        },
        {
          'type': 'Battery Voltage',
          'min': 0,
          'max': 0,
          'units': 'Volts',
          'enabled': true,
        },
        {
          'type': 'Solar Voltage',
          'min': 0,
          'max': 0,
          'units': 'Volts',
          'enabled': true,
        },
      ];
    }

    _channelEnabled = List.generate(
      _channels.length,
      (i) => _channels[i]['enabled'] ?? true,
    );
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_tankNumberController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter Tank Name')),
      );
      return;
    }

    if (_selectedSite == null && widget.tank?.siteId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Site')),
      );
      return;
    }

    if (_selectedProduct == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Product')),
      );
      return;
    }

    final isSuperAdmin = ref.read(userProvider).currentUser?.roleId == 1;
    if (isSuperAdmin && _selectedCompany == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Company')),
      );
      return;
    }

    final channelData = getChannelData();

    final request = TankCreateRequest(
      tankNumber: _tankNumberController.text,
      description: '',
      siteId: _selectedSite?.siteId ?? widget.tank?.siteId,
      addressId: _selectedSite?.addressId ?? widget.tank?.addressId,
      unitId: _selectedUnit?['id'],
      productId: _selectedProduct?.productId,
      channelData: channelData['channels'],
      companyId: _selectedCompany?.id ?? widget.tank?.companyId,
      ruleId: _selectedRule?.id,
      tankDimension: _selectedDimension?.id,
    );

    final success = widget.tank != null
        ? await ref
              .read(tankNotifierProvider.notifier)
              .updateTank(widget.tank!.tankId, request)
        : await ref.read(tankNotifierProvider.notifier).createTank(request);

    if (!mounted) return;

    if (success) {
      widget.onSuccess?.call();
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(widget.tank != null ? 'Tank updated' : 'Tank created'),
        ),
      );
    } else {
      final error = ref.read(tankNotifierProvider).error;
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
    final tankState = ref.watch(tankNotifierProvider);
    final tankDimState = ref.watch(tankDimensionNotifierProvider);
    final List<TankDimension> dimensions = tankDimState.tankDimensions;

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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tank != null
                                    ? 'Edit Tank Instance'
                                    : 'Create New Tank',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.tank != null
                                    ? 'Modify the existing tank configuration and properties.'
                                    : 'Fill in the information below to register a new tank unit.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 22),
                          color: const Color(0xFF6B7280),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    _buildLabelField('TANK ID', _buildTankAutocomplete()),
                    const SizedBox(height: 25),
                    if (ref.watch(userProvider).currentUser?.roleId == 1) ...[
                      _buildLabelField(
                        'PRIMARY COMPANY',
                        AppTextField(
                          readOnly: true,
                          controller: _companyAutocompleteController,
                          hint: 'Company',
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                    _buildLabelField('SITE', _buildSiteAutocomplete()),
                    const SizedBox(height: 25),
                    _buildLabelField(
                      'ASSIGNED PRODUCT',
                      _isLoadingDropdowns
                          ? const LinearProgressIndicator(minHeight: 2)
                          : AppDropdown<TankProduct>(
                              value: _selectedProduct,
                              items: _products,
                              itemLabel: (p) => p.productName,
                              hint: 'Select Product',
                              onChanged: (v) =>
                                  setState(() => _selectedProduct = v),
                            ),
                    ),
                    const SizedBox(height: 25),
                    _buildLabelField(
                      'TANK DIMENSION',
                      _isLoadingDropdowns
                          ? const LinearProgressIndicator(minHeight: 2)
                          : AppDropdown<TankDimension?>(
                              value: _selectedDimension,
                              items: [null, ...dimensions],
                              itemLabel: (dim) => dim == null ? 'Select Dimension' : dim.type,
                              hint: 'Select Dimension',
                              onChanged: (value) {
                                setState(() {
                                  _selectedDimension = value;
                                });
                              },
                            ),
                    ),
                    const SizedBox(height: 25),
                    _buildLabelField(
                      'EVENT RULE GROUP',
                      _isLoadingDropdowns
                          ? const LinearProgressIndicator(minHeight: 2)
                          : AppDropdown<TankRuleModel>(
                              value: _selectedRule,
                              items: _tankRules,
                              itemLabel: (rule) => rule.ruleName,
                              hint: 'Select rule',
                              onChanged: (value) {
                                setState(() {
                                  _selectedRule = value;
                                });
                              },
                            ),
                    ),
                    const SizedBox(height: 25),
                    _buildLabelField('DATA CHANNELS', _buildChannelsTable()),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: const Color(0xFF141E7A),
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Set the visibility of this tank record.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _buildStatusToggle(
                            1,
                            'Active',
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusToggle(
                            0,
                            'Inactive',
                            const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 64),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF141E7A),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(
                            0xFF141E7A,
                          ).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          widget.tank != null ? 'UPDATE TANK' : 'CREATE TANK',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (tankState.isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
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
        SizedBox(
          height: 20,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildStatusToggle(int value, String label, Color activeColor) {
    final isSelected = _status == value;
    return InkWell(
      onTap: () => setState(() => _status = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFD1D5DB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _tankNumberController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await ref
                .read(tankNotifierProvider.notifier)
                .getTankNameSuggestions(textEditingValue.text);
          },
          displayStringForOption: (String option) => option,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Enter Tank Name',
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
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
        onSelected: (o) {
          setState(() {
            _selectedCompany = o;
            _selectedSite = null;
            _siteAutocompleteController.clear();
          });
        },
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

  Widget _buildSiteAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<SiteAutocompleteInfo>(
          textEditingController: _siteAutocompleteController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<SiteAutocompleteInfo>.empty();
            }
            return await ref
                .read(tankNotifierProvider.notifier)
                .searchSites(
                  textEditingValue.text,
                  companyId: _selectedCompany?.id,
                );
          },
          displayStringForOption: (SiteAutocompleteInfo option) =>
              option.displayName ?? option.siteName,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search Site by Name',
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.displayName ??
                              "${option.siteName} ${option.fullAddress}",
                        ),
                        onTap: () {
                          onSelected(option);
                          setState(() {
                            _selectedSite = option;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChannelsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 600, maxWidth: 600),
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.resolveWith(
              (states) => const Color(0xFFF9FAFB),
            ),
            headingTextStyle: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
            dataTextStyle: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF111827),
            ),
            headingRowHeight: 40.0,
            dataRowMinHeight: 40.0,
            dataRowMaxHeight: 40.0,
            dividerThickness: 0.3,
            columns: [
              const DataColumn(
                label: Text('ENABLE'),
                columnWidth: FixedColumnWidth(70.0),
              ),
              const DataColumn(
                label: Text('TYPE'),
                columnWidth: FixedColumnWidth(
                  120.0,
                ), // Fixed width for type text
              ),
              const DataColumn(
                label: Text('MIN'),
                columnWidth: FixedColumnWidth(95.0),
              ),
              const DataColumn(
                label: Text('MAX'),
                columnWidth: FixedColumnWidth(95.0),
              ),
              const DataColumn(
                label: Text('UNITS'),
                columnWidth: FlexColumnWidth(1.0),
              ),
            ],
            rows: List.generate(_channels.length, (index) {
              final channel = _channels[index];
              final isEnabled = _channelEnabled[index];

              return DataRow(
                color: isEnabled
                    ? null
                    : WidgetStateProperty.resolveWith(
                        (states) => const Color(0xFFF9FAFB),
                      ),
                cells: [
                  DataCell(
                    SizedBox(
                      width: 40,
                      child: Checkbox(
                        value: isEnabled,
                        onChanged: (value) {
                          setState(() {
                            _channelEnabled[index] = value ?? false;
                            _channels[index]['enabled'] = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF141E7A),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      channel['type'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isEnabled
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: channel['min'].toString(),
                        enabled: isEnabled,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isEnabled
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF141E7A),
                              width: 1.5,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFF3F4F6),
                            ),
                          ),
                          filled: true,
                          fillColor: isEnabled
                              ? Colors.white
                              : const Color(0xFFF9FAFB),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _channels[index]['min'] = double.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: channel['max'].toString(),
                        enabled: isEnabled,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isEnabled
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFF141E7A),
                              width: 1.5,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: Color(0xFFF3F4F6),
                            ),
                          ),
                          filled: true,
                          fillColor: isEnabled
                              ? Colors.white
                              : const Color(0xFFF9FAFB),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _channels[index]['max'] = double.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        channel['units'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isEnabled
                              ? const Color(0xFF6B7280)
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> getChannelData() {
    return {
      'channels': _channels.map((channel) {
        final index = _channels.indexOf(channel);
        return {
          'type': channel['type'],
          'min': channel['min'],
          'max': channel['max'],
          'units': channel['units'],
          'enabled': _channelEnabled[index],
        };
      }).toList(),
    };
  }

  @override
  void dispose() {
    _tankNumberController.dispose();
    _descriptionController.dispose();
    _siteAutocompleteController.dispose();
    _companyAutocompleteController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
  }
}
