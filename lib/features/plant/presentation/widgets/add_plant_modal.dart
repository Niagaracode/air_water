import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/plant_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_autocomplete.dart';
import '../../../../shared/widgets/location_picker.dart';
import '../controller/plant_provider.dart';
import '../../../../core/user_config/user_role.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../company/presentation/model/company_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPlantModal extends ConsumerStatefulWidget {
  final Plant? initialPlant;
  const AddPlantModal({super.key, this.initialPlant});

  @override
  ConsumerState<AddPlantModal> createState() => _AddPlantModalState();
}

class AddressControllers {
  final addressController = TextEditingController();
  final pinCodeController = TextEditingController();
  String? country;
  String? state;
  String? city;
  CompanyAddress? selectedRegisteredAddress;
  bool isProgrammaticUpdate = false;

  void dispose() {
    addressController.dispose();
    pinCodeController.dispose();
  }

  void updateFromRegistered(CompanyAddress addr) {
    isProgrammaticUpdate = true;
    selectedRegisteredAddress = addr;
    isProgrammaticUpdate = false;
  }
}

class _AddPlantModalState extends ConsumerState<AddPlantModal> {
  final _nameController = TextEditingController();
  CompanyGroup? _selectedGroup;
  List<CompanyGroup> _companyGroups = [];
  final List<AddressControllers> _addressRows = [AddressControllers()];
  int _status = 1;
  bool _isLoadingCompanies = false;
  bool _showCompanyDropdown = true;
  String? _selectedPlantName;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlant != null) {
      _nameController.text = widget.initialPlant!.name;
      _status = widget.initialPlant!.status;
      _addressRows.first.addressController.text =
          widget.initialPlant!.addressLine1 ?? '';
      _addressRows.first.pinCodeController.text =
          widget.initialPlant!.pincode ?? '';
      _addressRows.first.country = widget.initialPlant!.countryName;
      _addressRows.first.state = widget.initialPlant!.stateName;
      _addressRows.first.city = widget.initialPlant!.cityName;
      _showCompanyDropdown = false;
      _selectedPlantName = widget.initialPlant!.name;
    }
    _nameController.addListener(_onNameChanged);
    Future.microtask(() => _loadInitialData());
  }

  void _onNameChanged() {
    if (_selectedPlantName != null &&
        _nameController.text != _selectedPlantName) {
      setState(() {
        _showCompanyDropdown = true;
        _selectedPlantName = null;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingCompanies = true);
    try {
      final repository = ref.read(companyRepositoryProvider);
      final response = await repository.getGroupedCompanies(limit: 1000);
      _companyGroups = response.data;

      final roleAsync = ref.read(userRoleProvider);
      final isSuperAdmin = roleAsync.asData?.value == UserRole.superAdmin;

      if (_companyGroups.isNotEmpty && !isSuperAdmin) {
        _onCompanyChanged(_companyGroups.first);
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCompanies = false);
        if (widget.initialPlant != null) {
          final initialGroup = _companyGroups
              .where(
                (g) => g.addresses.any(
                  (a) => a.companyId == widget.initialPlant!.companyId,
                ),
              )
              .firstOrNull;
          if (initialGroup != null) {
            _selectedGroup = initialGroup;
            _addressRows.first.selectedRegisteredAddress = initialGroup
                .addresses
                .where((a) => a.companyId == widget.initialPlant!.companyId)
                .firstOrNull;
          }
        }
      }
    }
  }

  void _onCompanyChanged(CompanyGroup? group) {
    setState(() {
      _selectedGroup = group;
      for (var row in _addressRows) {
        row.selectedRegisteredAddress = null;
        row.addressController.clear();
        row.pinCodeController.clear();
        row.country = null;
        row.state = null;
        row.city = null;
      }
      if (group != null &&
          group.addresses.length == 1 &&
          _addressRows.isNotEmpty) {
        _addressRows.first.updateFromRegistered(group.addresses.first);
      }
    });
  }

  void _addAddressRow() {
    setState(() {
      _addressRows.add(AddressControllers());
    });
  }

  void _removeAddressRow(int index) {
    if (_addressRows.length > 1) {
      setState(() {
        _addressRows[index].dispose();
        _addressRows.removeAt(index);
      });
    }
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Plant Name and select a Company'),
        ),
      );
      return;
    }

    for (var row in _addressRows) {
      if (row.addressController.text.isEmpty || row.country == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all address details')),
        );
        return;
      }
    }

    final addresses = _addressRows.map((row) {
      final resolvedCompanyId =
          row.selectedRegisteredAddress?.companyId ??
          _selectedGroup?.addresses.firstOrNull?.companyId;

      return CompanyAddress(
        addressLine1: row.addressController.text,
        pincode: row.pinCodeController.text,
        country: row.country ?? '',
        state: row.state ?? '',
        city: row.city ?? '',
        status: _status,
        companyId: resolvedCompanyId,
      );
    }).toList();

    final primaryCompanyId = addresses.first.companyId;

    if (primaryCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid company location')),
      );
      return;
    }

    final request = PlantCreateRequest(
      name: _nameController.text,
      companyId: primaryCompanyId,
      country: _addressRows.first.country,
      state: _addressRows.first.state,
      city: _addressRows.first.city,
      addresses: addresses,
    );

    final bool success;
    if (widget.initialPlant != null) {
      success = await ref
          .read(plantNotifierProvider.notifier)
          .updatePlant(widget.initialPlant!.id, request);
    } else {
      success = await ref
          .read(plantNotifierProvider.notifier)
          .createPlant(request);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantState = ref.watch(plantNotifierProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: SizedBox(
          width: 600,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top accent bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF141E7A),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
              ),
              Expanded(
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
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.initialPlant != null
                                          ? 'Edit Plant Details'
                                          : 'Register New Plant',
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Manage manufacturing units and operational sites.',
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
                          const SizedBox(height: 32),
                          _buildInfoBar(),
                          const SizedBox(height: 48),

                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'PLANT IDENTIFIER',
                                  AppAutocomplete<PlantAutocompleteInfo>(
                                    controller: _nameController,
                                    hint: 'e.g. South Plant Unit A',
                                    displayStringForOption: (plant) =>
                                        plant.plantName,
                                    subtitleBuilder: (plant) =>
                                        plant.companyName ?? '',
                                    optionsBuilder: (textEditingValue) async {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<
                                          PlantAutocompleteInfo
                                        >.empty();
                                      }
                                      return await ref
                                          .read(plantNotifierProvider.notifier)
                                          .searchPlants(textEditingValue.text);
                                    },
                                    onSelected: (plant) {
                                      setState(() {
                                        _showCompanyDropdown = false;
                                        _selectedPlantName = plant.plantName;
                                        if (_addressRows.isNotEmpty) {
                                          final row = _addressRows.first;

                                          // Also select the company and registered address if available
                                          if (plant.companyId != null) {
                                            final group = _companyGroups
                                                .where(
                                                  (g) => g.addresses.any(
                                                    (a) =>
                                                        a.companyId ==
                                                        plant.companyId,
                                                  ),
                                                )
                                                .firstOrNull;
                                            if (group != null) {
                                              _selectedGroup = group;
                                              row.selectedRegisteredAddress =
                                                  group.addresses
                                                      .where(
                                                        (a) =>
                                                            a.companyId ==
                                                            plant.companyId,
                                                      )
                                                      .firstOrNull;
                                            }
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Visibility(
                                  visible: _showCompanyDropdown,
                                  maintainState: true,
                                  child: _buildLabelField(
                                    'OWNING COMPANY',
                                    _isLoadingCompanies
                                        ? const LinearProgressIndicator(
                                            minHeight: 2,
                                          )
                                        : AppDropdown<CompanyGroup>(
                                            value: _selectedGroup,
                                            items: _companyGroups,
                                            hint: 'Select Company',
                                            itemLabel: (g) => g.name,
                                            onChanged: _onCompanyChanged,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),

                          // Section: Location Details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 18,
                                    color: Color(0xFF141E7A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SITE LOCATIONS',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF141E7A),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.initialPlant == null)
                                TextButton.icon(
                                  onPressed: _addAddressRow,
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'ADD SITE',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF141E7A),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(
                            height: 32,
                            thickness: 1,
                            color: Color(0xFFF3F4F6),
                          ),

                          ...List.generate(
                            _addressRows.length,
                            (index) => _buildAddressRow(index),
                          ),
                          const SizedBox(height: 40),

                          // Status Selector
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF3F4F6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PLANT STATUS',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: const Color(0xFF141E7A),
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Set the operational status of this site.',
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
                              onPressed: plantState.isProcessing ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF141E7A),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: plantState.isProcessing
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      widget.initialPlant != null
                                          ? 'UPDATE PLANT'
                                          : 'REGISTER PLANT',
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
                    if (plantState.isProcessing) ...[
                      Positioned.fill(
                        child: Container(
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(),
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
      ),
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

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE1FF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF141E7A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.initialPlant != null
                  ? 'Update site information and registry details.'
                  : 'Register a new manufacturing site or operational plant.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF141E7A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(int index) {
    final controllers = _addressRows[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        key: ValueKey(controllers),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SITE #${index + 1}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 1.5,
                ),
              ),
              if (_addressRows.length > 1 && widget.initialPlant == null)
                IconButton(
                  onPressed: () => _removeAddressRow(index),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedGroup != null &&
              _selectedGroup!.addresses.length > 1) ...[
            _buildLabelField(
              'REGISTERED ADDRESS',
              AppDropdown<CompanyAddress>(
                value: controllers.selectedRegisteredAddress,
                items: _selectedGroup?.addresses ?? [],
                hint: 'Select Company Location',
                itemLabel: (a) => a.fullAddress,
                onChanged: (a) {
                  if (a != null)
                    setState(() => controllers.updateFromRegistered(a));
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildLabelField(
                  'STREET ADDRESS',
                  AppTextField(
                    controller: controllers.addressController,
                    hint: 'Address Line 1',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLabelField(
                  'POSTAL CODE',
                  AppTextField(
                    controller: controllers.pinCodeController,
                    hint: 'PIN Code',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LocationPicker(
            key: ValueKey(
              'loc_${controllers.country}_${controllers.state}_${controllers.city}',
            ),
            currentCountry: controllers.country,
            currentState: controllers.state,
            currentCity: controllers.city,
            onCountryChanged: (value) {
              setState(() {
                controllers.country = value;
                controllers.state = null;
                controllers.city = null;
              });
            },
            onStateChanged: (value) {
              setState(() {
                controllers.state = value;
                controllers.city = null;
              });
            },
            onCityChanged: (value) {
              setState(() => controllers.city = value);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controllers in _addressRows) {
      controllers.dispose();
    }
    super.dispose();
  }
}
