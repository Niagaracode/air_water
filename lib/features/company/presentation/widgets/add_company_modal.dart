import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/company_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_autocomplete.dart';
import '../../../../shared/widgets/location_picker.dart';
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
  final _emailTemplateController = TextEditingController();
  List<CompanyAddressControllers> _addressRows = [];
  int _status = 1;

  @override
  void initState() {
    super.initState();
    if (widget.companyGroup != null && widget.initialAddress != null) {
      _nameController.text = widget.companyGroup!.name;
      _emailTemplateController.text = widget.companyGroup!.emailTemplate ?? '';
      _status = widget.initialAddress!.status;

      final controllers = CompanyAddressControllers();
      controllers.addressController.text =
          widget.initialAddress!.addressLine1 ?? '';
      controllers.pinCodeController.text = widget.initialAddress!.pincode ?? '';
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
        'email_template': _emailTemplateController.text.trim().isEmpty
            ? null
            : _emailTemplateController.text.trim(),
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
        emailTemplate: _emailTemplateController.text.trim().isEmpty
            ? null
            : _emailTemplateController.text.trim(),
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
                child: SingleChildScrollView(
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
                                  widget.initialAddress != null
                                      ? 'Edit Company'
                                      : 'Register New Company',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Manage corporate entities and their multiple operational addresses.',
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

                      // Company Name
                      _buildLabelField(
                        'COMPANY ENTITY NAME',
                        widget.initialAddress != null
                            ? TextField(
                          controller: _nameController,
                          enabled: true,
                          decoration: InputDecoration(
                            hintText: 'Enter Company name',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        )
                            : AppAutocomplete<String>(
                          controller: _nameController,
                          hint: 'e.g. Acme Corp Industries',
                          displayStringForOption: (option) => option,
                          optionsBuilder: (textEditingValue) async {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            final companies = await ref
                                .read(companyRepositoryProvider)
                                .getCompanyAutocomplete(
                              q: textEditingValue.text,
                            );
                            return companies.map((e) => e.name).toList();
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email Template
                      _buildLabelField(
                        'EMAIL',
                        AppTextField(
                          controller: _emailTemplateController,
                          hint: 'e.g. alerts@company.com',
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Location Details section header
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
                                'REGISTERED ADDRESSES',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF141E7A),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          if (widget.initialAddress == null)
                            TextButton.icon(
                              onPressed: _addAddressRow,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 16,
                              ),
                              label: Text(
                                'ADD ADDRESS',
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
                      const SizedBox(height: 8),
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
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ENTITY STATUS',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: const Color(0xFF141E7A),
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Set the visibility and active status of this entity.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            widget.initialAddress != null
                                ? 'UPDATE COMPANY'
                                : 'REGISTER COMPANY',
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
              'Specify the primary entity name and associated location addresses.',
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
              'ADDRESS #${index + 1}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 1.5,
              ),
            ),
            if (_addressRows.length > 1 && widget.initialAddress == null)
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
    _emailTemplateController.dispose();
    for (var controllers in _addressRows) {
      controllers.dispose();
    }
    super.dispose();
  }
}