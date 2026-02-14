import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/plant_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_radio_button.dart';
import '../../../../shared/widgets/location_picker.dart';
import '../controller/plant_provider.dart';
import '../../../../core/user_config/user_role.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../company/presentation/model/company_model.dart';

class AddPlantModal extends ConsumerStatefulWidget {
  final PlantGroupAddress? initialPlant;
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
    // addressController.text = addr.addressLine1;
    // pinCodeController.text = addr.pincode;
    // country = addr.country;
    // state = addr.state;
    // city = addr.city;
    selectedRegisteredAddress = addr;
    isProgrammaticUpdate = false;
  }
}

class _AddPlantModalState extends ConsumerState<AddPlantModal> {
  final _nameController = TextEditingController();
  CompanyGroup? _selectedGroup;
  List<CompanyGroup> _companyGroups = [];
  final List<AddressControllers> _addressRows = [AddressControllers()];
  int _status = 1; // 1 for Active, 0 for Inactive
  bool _isLoadingCompanies = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlant != null) {
      _nameController.text = widget.initialPlant!.plantName ?? '';
      _status = widget.initialPlant!.status ?? 1;
      _addressRows.first.addressController.text =
          widget.initialPlant!.addressLine1 ?? '';
      _addressRows.first.pinCodeController.text =
          widget.initialPlant!.pincode ?? '';
      _addressRows.first.country = widget.initialPlant!.country;
      _addressRows.first.state = widget.initialPlant!.state;
      _addressRows.first.city = widget.initialPlant!.city;
    }
    Future.microtask(() => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingCompanies = true);
    try {
      final repository = ref.read(companyRepositoryProvider);

      // For Super Admin, fetch all unique company names
      final roleAsync = ref.read(userRoleProvider);
      final isSuperAdmin = roleAsync.asData?.value == UserRole.superAdmin;

      if (isSuperAdmin) {
        final response = await repository.getGroupedCompanies(limit: 100);
        _companyGroups = response.data;
      } else {
        final response = await repository.getGroupedCompanies(limit: 100);
        _companyGroups = response.data;
      }

      if (_companyGroups.isNotEmpty && !isSuperAdmin) {
        // Auto-select if only one (common for non-super-admins)
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
      // Reset all address rows when company group changes
      for (var row in _addressRows) {
        row.selectedRegisteredAddress = null;
        row.addressController.clear();
        row.pinCodeController.clear();
        row.country = null;
        row.state = null;
        row.city = null;
      }

      // Auto-populate if only one address exists
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

    // Validation for addresses
    for (var row in _addressRows) {
      if (row.addressController.text.isEmpty || row.country == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete all address details')),
        );
        return;
      }
    }

    final addresses = _addressRows.map((row) {
      // Fallback: If no specific location is selected (e.g. manually edited or single address hidden),
      // use the companyId from the first address in the group if available.
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

    // The primary company ID used by the backend as a default if not provided per address
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
          .updatePlant(widget.initialPlant!.plantId!, request);
    } else {
      success = await ref
          .read(plantNotifierProvider.notifier)
          .createPlant(request);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialPlant != null
                ? 'Plant updated successfully'
                : 'Plant created successfully',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    final plantState = ref.watch(plantNotifierProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Stack(
          children: [
            Container(
              width: 600,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.initialPlant != null
                              ? 'EDIT PLANT'
                              : 'ADD NEW PLANT',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: infoBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: primaryDeep, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.initialPlant != null
                                  ? 'Update The Plant Details And Locations.'
                                  : 'Enter The Plant Name And Specify Registered Locations.',
                              style: const TextStyle(
                                color: Color(0xFF1B1B4B),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    roleAsync.when(
                      data: (role) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Plant Name*',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AppTextField(
                                        controller: _nameController,
                                        hint: 'Enter plant name',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Company Name*',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _isLoadingCompanies
                                          ? const LinearProgressIndicator()
                                          : AppDropdown<CompanyGroup>(
                                              value: _selectedGroup,
                                              items: _companyGroups,
                                              hint: 'Select Company',
                                              itemLabel: (g) => g.name,
                                              onChanged: _onCompanyChanged,
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'LOCATION DETAILS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                    fontSize: 14,
                                  ),
                                ),
                                if (widget.initialPlant == null)
                                  ElevatedButton.icon(
                                    onPressed: _addAddressRow,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('ADD'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryDeep,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 32),
                            ...List.generate(
                              _addressRows.length,
                              (index) => _buildAddressRow(index),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'STATUS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                AppRadioButton<int>(
                                  value: 1,
                                  groupValue: _status,
                                  label: 'ACTIVE',
                                  onChanged: (v) =>
                                      setState(() => _status = v!),
                                ),
                                const SizedBox(width: 32),
                                AppRadioButton<int>(
                                  value: 0,
                                  groupValue: _status,
                                  label: 'INACTIVE',
                                  onChanged: (v) =>
                                      setState(() => _status = v!),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => SizedBox(
                        height: 200,
                        child: Center(child: Text('Error: $err')),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryDeep,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.initialPlant != null ? 'UPDATE' : 'SAVE',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (plantState.isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(int index) {
    final controllers = _addressRows[index];

    return Column(
      key: ValueKey(controllers),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedGroup != null &&
                      _selectedGroup!.addresses.length > 1) ...[
                    AppDropdown<CompanyAddress>(
                      value: controllers.selectedRegisteredAddress,
                      items: _selectedGroup?.addresses ?? [],
                      hint: 'Select Company Location',
                      itemLabel: (a) => a.fullAddress,
                      onChanged: (a) {
                        if (a != null) {
                          setState(() {
                            controllers.updateFromRegistered(a);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (widget.initialPlant == null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () => _removeAddressRow(index),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: controllers.addressController,
                hint: 'Address Line 1',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: controllers.pinCodeController,
                hint: 'PIN Code',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LocationPicker(
          key: ValueKey(
            'loc_${controllers.country}_${controllers.state}_${controllers.city}',
          ),
          currentCountry: controllers.country,
          currentState: controllers.state,
          currentCity: controllers.city,
          onCountryChanged: (value) {
            setState(() {
              // controllers.selectedRegisteredAddress = null;
              controllers.country = value;
              controllers.state = null;
              controllers.city = null;
            });
          },
          onStateChanged: (value) {
            setState(() {
              // controllers.selectedRegisteredAddress = null;
              controllers.state = value;
              controllers.city = null;
            });
          },
          onCityChanged: (value) {
            setState(() {
              // controllers.selectedRegisteredAddress = null;
              controllers.city = value;
            });
          },
        ),
        if (index != _addressRows.length - 1) const Divider(height: 48),
        if (index == _addressRows.length - 1) const SizedBox(height: 32),
      ],
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
