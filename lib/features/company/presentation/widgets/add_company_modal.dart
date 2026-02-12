import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import '../model/company_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_radio_button.dart';
import '../../../../shared/widgets/app_autocomplete.dart';
import '../controller/company_provider.dart';
import '../../../../core/app_theme/app_theme.dart';

class AddCompanyModal extends ConsumerStatefulWidget {
  final CompanyGroup? companyGroup;
  final CompanyAddress? initialAddress;

  const AddCompanyModal({super.key, this.companyGroup, this.initialAddress});

  @override
  ConsumerState<AddCompanyModal> createState() => _AddCompanyModalState();
}

class CompanyAddressControllers {
  final addressController = TextEditingController();
  final pinCodeController = TextEditingController();
  String? country;
  String? state;
  String? city;
  int status = 1;

  void dispose() {
    addressController.dispose();
    pinCodeController.dispose();
  }
}

class _AddCompanyModalState extends ConsumerState<AddCompanyModal> {
  final _nameController = TextEditingController();
  List<CompanyAddressControllers> _addressRows = [];
  int _status = 1;

  @override
  void initState() {
    super.initState();
    if (widget.companyGroup != null && widget.initialAddress != null) {
      _nameController.text = widget.companyGroup!.name;
      _status = widget.initialAddress!.status;

      final controllers = CompanyAddressControllers();
      controllers.addressController.text = widget.initialAddress!.addressLine1;
      controllers.pinCodeController.text = widget.initialAddress!.pincode;
      controllers.country = widget.initialAddress!.country;
      controllers.state = widget.initialAddress!.state;
      controllers.city = widget.initialAddress!.city;
      controllers.status = widget.initialAddress!.status;
      _addressRows = [controllers];
    } else {
      _addressRows = [CompanyAddressControllers()];
    }
  }

  void _addAddressRow() {
    setState(() {
      _addressRows.add(CompanyAddressControllers());
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
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Company Name')),
      );
      return;
    }

    // Validation for addresses
    for (var row in _addressRows) {
      if (row.addressController.text.isEmpty ||
          row.pinCodeController.text.isEmpty ||
          row.country == null ||
          row.state == null ||
          row.city == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all address fields')),
        );
        return;
      }
    }

    if (widget.initialAddress != null &&
        widget.initialAddress!.companyId != null) {
      // Edit Mode
      final row = _addressRows.first;
      final updateData = {
        'name': _nameController.text,
        'country': row.country,
        'state': row.state,
        'city': row.city,
        'status': _status,
        'pincode': row.pinCodeController.text,
        'address_line_1': row.addressController.text,
      };

      final success = await ref
          .read(companyNotifierProvider.notifier)
          .updateCompany(widget.initialAddress!.companyId!, updateData);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company updated successfully')),
        );
      }
    } else {
      // Add Mode
      final addresses = _addressRows.map((row) {
        return CompanyAddress(
          addressLine1: row.addressController.text,
          pincode: row.pinCodeController.text,
          country: row.country!,
          state: row.state!,
          city: row.city!,
          status: _status,
        );
      }).toList();

      final request = CompanyCreateRequest(
        name: _nameController.text,
        createdBy: 1,
        addresses: addresses,
      );

      final success = await ref
          .read(companyNotifierProvider.notifier)
          .createCompany(request);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company created successfully')),
        );
      }
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
                    Text(
                      widget.initialAddress != null
                          ? 'EDIT COMPANY'
                          : 'ADD NEW COMPANY',
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
                          'Enter The Company Name, And Specify Multiple Addresses.',
                          style: TextStyle(color: primaryDeep, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Company Name*',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                AppAutocomplete<String>(
                  controller: _nameController,
                  hint: 'Enter Company name',
                  displayStringForOption: (option) => option,
                  optionsBuilder: (textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return await ref
                        .read(companyRepositoryProvider)
                        .getAutocompleteSuggestions(textEditingValue.text);
                  },
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
                    if (widget.initialAddress == null)
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    'Address 1*',
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
            if (widget.initialAddress == null)
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
        CSCPickerPlus(
          layout: Layout.horizontal,
          flagState: CountryFlag.DISABLE,
          onCountryChanged: (value) {
            setState(() {
              controllers.country = value;
            });
          },
          onStateChanged: (value) {
            setState(() {
              controllers.state = value;
            });
          },
          onCityChanged: (value) {
            setState(() {
              controllers.city = value;
            });
          },
          selectedItemStyle: const TextStyle(fontSize: 14),
          dropdownHeadingStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          dropdownItemStyle: const TextStyle(fontSize: 14),
          dropdownDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          disabledDropdownDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade100,
          ),
          currentCountry: controllers.country,
          currentState: controllers.state,
          currentCity: controllers.city,
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
