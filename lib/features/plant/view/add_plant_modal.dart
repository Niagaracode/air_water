import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/plant_model.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_radio_button.dart';
import '../controller/plant_provider.dart';
import '../../../core/user_config/user_role.dart';
import '../../../core/user_config/user_role_provider.dart';
import '../../company/presentation/controller/company_provider.dart';
import '../../../shared/widgets/app_autocomplete.dart';
import '../../../core/app_theme/app_theme.dart';
import '../../company/presentation/model/company_model.dart';

class AddPlantModal extends ConsumerStatefulWidget {
  const AddPlantModal({super.key});

  @override
  ConsumerState<AddPlantModal> createState() => _AddPlantModalState();
}

class AddressControllers {
  final addressController = TextEditingController();
  final pinCodeController = TextEditingController();
  String? country;
  String? state;
  String? city;

  void dispose() {
    addressController.dispose();
    pinCodeController.dispose();
  }
}

class _AddPlantModalState extends ConsumerState<AddPlantModal> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final List<AddressControllers> _addressRows = [AddressControllers()];
  int _status = 1; // 1 for Active, 0 for Inactive

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
    final roleAsync = ref.read(userRoleProvider);
    final isSuperAdmin = roleAsync.asData?.value == UserRole.superAdmin;

    // Basic validation
    if (_nameController.text.isEmpty ||
        (isSuperAdmin && _companyController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuperAdmin
                ? 'Please fill in Plant Name and Company Name'
                : 'Please fill in Plant Name',
          ),
        ),
      );
      return;
    }

    final locations = _addressRows.map((row) {
      return PlantLocation(
        address: row.addressController.text,
        pinCode: row.pinCodeController.text,
        country: row.country ?? '',
        state: row.state ?? '',
        city: row.city ?? '',
      );
    }).toList();

    final request = PlantCreateRequest(
      name: _nameController.text,
      companyName: _companyController.text,
      locations: locations,
      status: _status,
    );

    final success = await ref
        .read(plantNotifierProvider.notifier)
        .createPlant(request);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plant created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
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
                    const Text(
                      'ADD NEW PLANT',
                      style: TextStyle(
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
                      const Expanded(
                        child: Text(
                          'Enter The Plant Name And Specify Multiple Addresses.',
                          style: TextStyle(
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
                    final isSuperAdmin = role == UserRole.superAdmin;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                            if (isSuperAdmin) ...[
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Company Name*',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AppAutocomplete<CompanyGroup>(
                                      controller: _companyController,
                                      hint: 'Enter Company Name',
                                      displayStringForOption: (option) =>
                                          option.name,
                                      optionsBuilder: (textEditingValue) async {
                                        if (textEditingValue.text.isEmpty) {
                                          return const Iterable<
                                            CompanyGroup
                                          >.empty();
                                        }
                                        final response = await ref
                                            .read(companyRepositoryProvider)
                                            .getGroupedCompanies(
                                              search: textEditingValue.text,
                                            );
                                        return response.data
                                            as Iterable<CompanyGroup>;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                            const SizedBox(width: 32),
                            AppRadioButton<int>(
                              value: 0,
                              groupValue: _status,
                              label: 'INACTIVE',
                              onChanged: (v) => setState(() => _status = v!),
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
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
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
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address*',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: controllers.addressController,
                    hint: 'Enter Address',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PIN code*',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: controllers.pinCodeController,
                    hint: 'Enter PIN Code',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Country*',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  AppDropdown<String>(
                    value: controllers.country,
                    items: const ['India', 'USA', 'UK'],
                    hint: 'Select Country',
                    itemLabel: (v) => v,
                    onChanged: (v) => setState(() => controllers.country = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'State*',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  AppDropdown<String>(
                    value: controllers.state,
                    items: const ['Tamil Nadu', 'Karnataka', 'California'],
                    hint: 'Select State',
                    itemLabel: (v) => v,
                    onChanged: (v) => setState(() => controllers.state = v),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'City*',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  AppDropdown<String>(
                    value: controllers.city,
                    items: const ['Chennai', 'Bangalore', 'Los Angeles'],
                    hint: 'Select City',
                    itemLabel: (v) => v,
                    onChanged: (v) => setState(() => controllers.city = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (index != _addressRows.length - 1) const Divider(height: 48),
        if (index == _addressRows.length - 1) const SizedBox(height: 32),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    for (var controllers in _addressRows) {
      controllers.dispose();
    }
    super.dispose();
  }
}
