import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/site_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_autocomplete.dart';
import '../../../../shared/widgets/location_picker.dart';
import '../controller/site_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/utils/time_zones.dart';
import '../../../../core/app_theme/app_theme.dart';

const Map<String, String> _countryDialCodes = {
  'India': '+91',
  'United States': '+1',
  'United Kingdom': '+44',
  'United Arab Emirates': '+971',
  'Canada': '+1',
  'Australia': '+61',
  'Singapore': '+65',
  'Malaysia': '+60',
  'Germany': '+49',
  'France': '+33',
  'Japan': '+81',
  'China': '+86',
  'Brazil': '+55',
  'South Africa': '+27',
  'Saudi Arabia': '+966',
  'Qatar': '+974',
  'Oman': '+968',
  'Kuwait': '+965',
  'Bahrain': '+973',
  'Sri Lanka': '+94',
  'Bangladesh': '+880',
  'Pakistan': '+92',
  'Nepal': '+977',
  'Indonesia': '+62',
  'Thailand': '+66',
  'Vietnam': '+84',
  'Philippines': '+63',
  'New Zealand': '+64',
  'Mexico': '+52',
  'Spain': '+34',
  'Italy': '+39',
  'Netherlands': '+31',
  'Switzerland': '+41',
  'Sweden': '+46',
};

const List<String> _commonDialCodes = [
  '+91',
  '+1',
  '+44',
  '+971',
  '+61',
  '+65',
  '+60',
  '+49',
  '+33',
  '+81',
  '+86',
  '+966',
  '+974',
  '+968',
  '+965',
  '+973',
  '+94',
  '+880',
  '+92',
  '+977',
  '+62',
  '+66',
  '+84',
  '+63',
  '+64',
  '+52',
  '+34',
  '+39',
  '+31',
  '+41',
  '+46',
  '+27',
  '+55',
];

class AddSiteModal extends ConsumerStatefulWidget {
  final Site? initialSite;
  final int? targetAddressId;
  const AddSiteModal({super.key, this.initialSite, this.targetAddressId});

  @override
  ConsumerState<AddSiteModal> createState() => _AddSiteModalState();
}

class AddressControllers {
  int? id;
  final addressController = TextEditingController();
  final address2Controller = TextEditingController();
  final address3Controller = TextEditingController();

  final pinCodeController = TextEditingController();
  final contactController = TextEditingController();
  final timeZoneController = TextEditingController();
  String? country;

  String? state;
  String? city;
  String selectedCountryCode = '+91';
  bool isProgrammaticUpdate = false;

  void dispose() {
    addressController.dispose();
    address2Controller.dispose();
    address3Controller.dispose();
    pinCodeController.dispose();
    contactController.dispose();
    timeZoneController.dispose();
  }
}

class _AddSiteModalState extends ConsumerState<AddSiteModal> {
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final List<AddressControllers> _addressRows = [AddressControllers()];
  int _status = 1;
  bool _isLoadingCompanies = false;
  String? _selectedSiteName;

  @override
  void initState() {
    super.initState();
    if (widget.initialSite != null) {
      _nameController.text = widget.initialSite!.name;
      _status = widget.initialSite!.status;
      _addressRows.first.addressController.text =
          widget.initialSite!.addressLine1 ?? '';
      _addressRows.first.address2Controller.text =
          widget.initialSite!.addressLine2 ?? '';
      _addressRows.first.address3Controller.text =
          widget.initialSite!.addressLine3 ?? '';
      _addressRows.first.pinCodeController.text =
          widget.initialSite!.pincode ?? '';
      _parseContactNumber(_addressRows.first, widget.initialSite!.contactNumber);
      _addressRows.first.country = widget.initialSite!.countryName;
      _addressRows.first.state = widget.initialSite!.stateName;
      _addressRows.first.city = widget.initialSite!.cityName;
      if (_addressRows.first.country != null &&
          _countryDialCodes.containsKey(_addressRows.first.country)) {
        _addressRows.first.selectedCountryCode =
            _countryDialCodes[_addressRows.first.country]!;
      }
      _addressRows.first.timeZoneController.text =
          widget.initialSite!.timeZone ?? '';
      _selectedSiteName = widget.initialSite!.name;
    }
    _nameController.addListener(_onNameChanged);

    Future.microtask(() => _loadInitialData());
  }

  void _parseContactNumber(AddressControllers controllers, String? rawContact) {
    if (rawContact == null || rawContact.trim().isEmpty) {
      controllers.contactController.text = '';
      return;
    }
    final trimmed = rawContact.trim();
    final match = RegExp(r'^(\+\d{1,4})[\s\-]*(.*)$').firstMatch(trimmed);
    if (match != null) {
      final code = match.group(1)!;
      final rest = match.group(2)!;
      controllers.selectedCountryCode = code;
      controllers.contactController.text = rest;
    } else {
      controllers.contactController.text = trimmed;
    }
  }

  void _onNameChanged() {
    if (_selectedSiteName != null &&
        _nameController.text != _selectedSiteName) {
      setState(() {
        _selectedSiteName = null;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingCompanies = true);

    if (mounted && widget.initialSite != null) {
      try {
        final siteRepo = ref.read(siteRepositoryProvider);
        final addressesData = await siteRepo.getSiteWithAddresses(
          widget.initialSite!.id,
        );

        if (addressesData.isNotEmpty && mounted) {
          setState(() {
            var finalAddresses = addressesData;
            if (widget.targetAddressId != null) {
              finalAddresses = addressesData
                  .where(
                    (a) =>
                        a['address_id'].toString() ==
                        widget.targetAddressId.toString(),
                  )
                  .toList();
            }

            for (int i = 0; i < finalAddresses.length; i++) {
              final addrJson = finalAddresses[i];
              final controllers = i < _addressRows.length
                  ? _addressRows[i]
                  : AddressControllers();

              controllers.id = addrJson['address_id'] as int?;
              controllers.addressController.text =
                  addrJson['address_line_1'] ?? '';
              controllers.address2Controller.text =
                  addrJson['address_line_2'] ?? '';
              controllers.address3Controller.text =
                  addrJson['address_line_3'] ?? '';
              controllers.pinCodeController.text =
                  addrJson['pincode'] ?? '';
              _parseContactNumber(
                  controllers, addrJson['contact_number'] as String?);
              controllers.timeZoneController.text =
                  addrJson['time_zone'] ?? '';
              controllers.country = addrJson['country_name'] ?? addrJson['country'];
              controllers.state = addrJson['state_name'] ?? addrJson['state'];
              controllers.city = addrJson['city_name'] ?? addrJson['city'];

              if (controllers.country != null &&
                  _countryDialCodes.containsKey(controllers.country)) {
                controllers.selectedCountryCode =
                    _countryDialCodes[controllers.country]!;
              }

              if (i >= _addressRows.length) {
                _addressRows.add(controllers);
              }
            }

            if (_addressRows.length > finalAddresses.length) {
              for (int j = _addressRows.length - 1; j >= finalAddresses.length; j--) {
                _addressRows[j].dispose();
                _addressRows.removeAt(j);
              }
            }
          });
        }
      } catch (e) {
        debugPrint('Error fetching plant addresses: $e');
      }
    }
  }


  void _addAddressRow() {
    setState(() {
      final newRow = AddressControllers();
      // If we have an existing row, maybe default the timezone?
      if (_addressRows.isNotEmpty) {
        newRow.timeZoneController.text =
            _addressRows.first.timeZoneController.text;
      }
      _addressRows.add(newRow);
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
    final siteName = _nameController.text.trim();
    if (siteName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Site Name'),
        ),
      );
      return;
    }

    String? sanitize(String? str) {
      if (str == null) return null;
      final trimmed = str.trim();
      if (trimmed.isEmpty || trimmed == '--' || trimmed.toLowerCase() == 'null') return null;
      return trimmed;
    }

    for (int i = 0; i < _addressRows.length; i++) {
      final row = _addressRows[i];
      final country = sanitize(row.country);
      final address1 = sanitize(row.addressController.text);
      if (address1 == null || country == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter Address Line 1 and Country for Address #${i + 1}')),
        );
        return;
      }
    }

    final addressesList = _addressRows.map((row) {
      final phoneBody = sanitize(row.contactController.text);
      final fullContact = phoneBody != null
          ? '${row.selectedCountryCode} $phoneBody'
          : null;

      return SiteAddressRequest(
        id: row.id,
        addressLine1: sanitize(row.addressController.text),
        addressLine2: sanitize(row.address2Controller.text),
        addressLine3: sanitize(row.address3Controller.text),
        pincode: sanitize(row.pinCodeController.text),
        contactNumber: fullContact,
        country: sanitize(row.country),
        state: sanitize(row.state),
        city: sanitize(row.city),
        timeZone: sanitize(row.timeZoneController.text),
      );
    }).toList();

    final firstRow = _addressRows.first;

    final request = SiteCreateRequest(
      name: siteName,
      orgCode: '',
      country: sanitize(firstRow.country),
      state: sanitize(firstRow.state),
      city: sanitize(firstRow.city),
      timeZone: sanitize(firstRow.timeZoneController.text),
      status: _status,
      isPartialUpdate: widget.targetAddressId != null,
      addresses: addressesList,
    );

    final bool success;
    if (widget.initialSite != null) {
      success = await ref
          .read(siteNotifierProvider.notifier)
          .updateSite(widget.initialSite!.id, request);
    } else {
      success = await ref
          .read(siteNotifierProvider.notifier)
          .createSite(request);
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteNotifierProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
        child: SafeArea(
          child: SizedBox(
            width: isMobile ? double.infinity : 600,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 40,
                    vertical: isMobile ? 24 : 48,
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
                                  widget.initialSite != null
                                      ? 'Edit Site Details'
                                      : 'Register New Site',
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

                      if (isMobile) ...[
                        _buildLabelField(
                          'CUSTOMER NAME',
                          AppAutocomplete<SiteAutocompleteInfo>(
                            controller: _nameController,
                            hint: 'e.g. South Site Unit A',
                            displayStringForOption: (site) => site.siteName,
                            subtitleBuilder: (site) => site.companyName ?? '',
                            optionsBuilder: (textEditingValue) async {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<
                                  SiteAutocompleteInfo
                                >.empty();
                              }
                              return await ref
                                  .read(siteNotifierProvider.notifier)
                                  .searchSites(textEditingValue.text);
                            },
                            onSelected: (site) {
                              setState(() {
                                _selectedSiteName = site.siteName;
                              });
                            },
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildLabelField(
                                'CUSTOMER NAME',
                                AppAutocomplete<SiteAutocompleteInfo>(
                                  controller: _nameController,
                                  hint: 'e.g. South Site Unit A',
                                  displayStringForOption: (site) =>
                                      site.siteName,
                                  subtitleBuilder: (site) => site.companyName ?? '',
                                  optionsBuilder: (textEditingValue) async {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<
                                        SiteAutocompleteInfo
                                      >.empty();
                                    }
                                    return await ref
                                        .read(siteNotifierProvider.notifier)
                                        .searchSites(textEditingValue.text);
                                  },
                                  onSelected: (site) {
                                    setState(() {
                                      _selectedSiteName = site.siteName;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Section: Location Details
                      ...List.generate(
                        _addressRows.length,
                        (index) => _buildAddressRow(index),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: []),
                          OutlinedButton.icon(
                            onPressed: _addAddressRow,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                            ),
                            label: Text(
                              'ADD NEW ADDRESS',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide(color: primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: primary.withValues(
                                alpha: 0.05,
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

                      // Status Selector
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STATUS',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: primary,
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
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatusToggle(
                                          1,
                                          'Active',
                                          const Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatusToggle(
                                          0,
                                          'Inactive',
                                          const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'STATUS',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: primary,
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
                          onPressed: siteState.isProcessing ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: siteState.isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  widget.initialSite != null
                                      ? 'UPDATE SITE'
                                      : 'REGISTER SITE',
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
                if (siteState.isProcessing) ...[
                  Positioned.fill(
                    child: Container(
                      color: Colors.black12,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              ],
            ),
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
          mainAxisAlignment: MainAxisAlignment.center,
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
          Icon(Icons.info_outline_rounded, size: 18, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.initialSite != null
                  ? 'Update site information and registry details.'
                  : 'Register a new manufacturing site or operational plant.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: primary,
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
              if (_addressRows.length > 1 && widget.initialSite == null)
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
          LocationPicker(
            key: ValueKey(
              'loc_${controllers.country}_${controllers.state}_${controllers.city}',
            ),
            isVertical: MediaQuery.sizeOf(context).width < 600,
            currentCountry: controllers.country,
            currentState: controllers.state,
            currentCity: controllers.city,
            onCountryChanged: (value) {
              setState(() {
                controllers.country = value;
                controllers.state = null;
                controllers.city = null;
                if (value != null && _countryDialCodes.containsKey(value)) {
                  controllers.selectedCountryCode = _countryDialCodes[value]!;
                }
                final defaultTz = TimeZoneUtils.getDefaultTimeZoneForCountry(
                  value,
                );
                if (defaultTz != null) {
                  controllers.timeZoneController.text = defaultTz;
                }
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
          const SizedBox(height: 24),
          _buildLabelField(
            'ADDRESS LINE 1',
            AppTextField(
              controller: controllers.addressController,
              hint: 'Address Line 1',
            ),
          ),
          const SizedBox(height: 24),
          _buildLabelField(
            'ADDRESS LINE 2',
            AppTextField(
              controller: controllers.address2Controller,
              hint: 'Address Line 2',
            ),
          ),
          const SizedBox(height: 24),
          _buildLabelField(
            'ADDRESS LINE 3',
            AppTextField(
              controller: controllers.address3Controller,
              hint: 'Address Line 3',
            ),
          ),
          const SizedBox(height: 24),
          _buildLabelField(
            'POSTAL CODE',
            AppTextField(
              controller: controllers.pinCodeController,
              hint: 'PIN Code',
            ),
          ),
          const SizedBox(height: 24),
          _buildLabelField(
            'CONTACT NUMBER',
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: AppDropdown<String>(
                    value: controllers.selectedCountryCode,
                    hint: 'Code',
                    items: _commonDialCodes.contains(controllers.selectedCountryCode)
                        ? _commonDialCodes
                        : [controllers.selectedCountryCode, ..._commonDialCodes],
                    itemLabel: (code) => code,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          controllers.selectedCountryCode = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: controllers.contactController,
                    hint: '98765 43210',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-]')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // LocationPicker(
          //   key: ValueKey(
          //     'loc_${controllers.country}_${controllers.state}_${controllers.city}',
          //   ),
          //   currentCountry: controllers.country,
          //   currentState: controllers.state,
          //   currentCity: controllers.city,
          //   onCountryChanged: (value) {
          //     setState(() {
          //       controllers.country = value;
          //       controllers.state = null;
          //       controllers.city = null;
          //     });
          //   },
          //   onStateChanged: (value) {
          //     setState(() {
          //       controllers.state = value;
          //       controllers.city = null;
          //     });
          //   },

          //   onCityChanged: (value) {
          //     setState(() => controllers.city = value);
          //   },
          // ),
          // const SizedBox(height: 24),
          _buildLabelField(
            'TIME ZONE REGION',
            _buildTimeZoneAutocomplete(controllers.timeZoneController),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeZoneAutocomplete(TextEditingController controller) {
    return AppAutocomplete<String>(
      controller: controller,
      hint: 'Search Time Zone (e.g. Asia/Kolkata)',
      displayStringForOption: (option) => option,
      onSelected: (String selection) {
        controller.text = selection;
        setState(() {});
      },
      optionsBuilder: (textEditingValue) async {
        // If text is empty and we have an initial value in layout_controller, show all or filtered?
        // Actually, just follow standard behavior.
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return TimeZoneUtils.ianaTimeZones.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _companyNameController.dispose();
    for (var controllers in _addressRows) {
      controllers.dispose();
    }
    super.dispose();
  }
}
