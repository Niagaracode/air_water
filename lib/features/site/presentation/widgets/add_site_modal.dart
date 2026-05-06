import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/site_model.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_autocomplete.dart';
import '../../../../shared/widgets/location_picker.dart';
import '../controller/site_provider.dart';
import '../../../../core/user_config/user_role.dart';
import '../../../../core/user_config/user_role_provider.dart';
import '../../../company/presentation/controller/company_provider.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../company/presentation/model/company_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/utils/time_zones.dart';

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

  final pinCodeController = TextEditingController();
  final contactController = TextEditingController();
  final timeZoneController = TextEditingController();
  String? country;

  String? state;
  String? city;
  CompanyAddress? selectedRegisteredAddress;
  bool isProgrammaticUpdate = false;

  void dispose() {
    addressController.dispose();
    pinCodeController.dispose();
    contactController.dispose();
    timeZoneController.dispose();
  }


  void updateFromRegistered(CompanyAddress addr) {
    isProgrammaticUpdate = true;
    selectedRegisteredAddress = addr;
    addressController.text = addr.addressLine1 ?? '';
    pinCodeController.text = addr.pincode ?? '';

    contactController.text = addr.contactNumber ?? '';
    timeZoneController.text = addr.timeZone ?? '';
    country = addr.country;
    state = addr.state;
    city = addr.city;
    isProgrammaticUpdate = false;
  }

}

class _AddSiteModalState extends ConsumerState<AddSiteModal> {
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  CompanyGroup? _selectedGroup;
  List<CompanyGroup> _companyGroups = [];
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
      _addressRows.first.pinCodeController.text =
          widget.initialSite!.pincode ?? '';
      _addressRows.first.contactController.text =
          widget.initialSite!.contactNumber ?? '';
      _addressRows.first.country = widget.initialSite!.countryName;
      _addressRows.first.state = widget.initialSite!.stateName;
      _addressRows.first.city = widget.initialSite!.cityName;
      _addressRows.first.timeZoneController.text = widget.initialSite!.timeZone ?? '';
      _selectedSiteName = widget.initialSite!.name;
    }
    _nameController.addListener(_onNameChanged);

    Future.microtask(() => _loadInitialData());
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
    try {
      final repository = ref.read(companyRepositoryProvider);
      final response = await repository.getGroupedCompanies(limit: 1000);
      _companyGroups = response.data;

      // Explicitly wait for role if it's still loading
      final roleAsync = await ref.read(userRoleProvider.future);
      final isSuperAdmin = roleAsync == UserRole.superAdmin;

      if (_companyGroups.isNotEmpty && !isSuperAdmin) {
        _onCompanyChanged(_companyGroups.first);
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCompanies = false);
        if (widget.initialSite != null) {
          // Find initial group
          final initialGroup = _companyGroups
              .where(
                (g) => g.addresses.any(
                  (a) => a.companyId == widget.initialSite!.companyId,
                ),
              )
              .firstOrNull;
          if (initialGroup != null) {
            _selectedGroup = initialGroup;
          }

          // Fetch ALL addresses for this plant
          try {
            final siteRepo = ref.read(siteRepositoryProvider);
            final addressesData = await siteRepo.getSiteWithAddresses(widget.initialSite!.id);
            
            if (addressesData.isNotEmpty) {
              setState(() {
                // Dispose existing rows first
                for (var row in _addressRows) {
                  row.dispose();
                }
                _addressRows.clear();
                
                // If targetAddressId is provided, filter to show only that address
                var finalAddresses = addressesData;
                if (widget.targetAddressId != null) {
                  finalAddresses = addressesData
                      .where((a) => a['address_id'].toString() == widget.targetAddressId.toString())
                      .toList();


                }

                for (var addrJson in finalAddresses) {
                  final controllers = AddressControllers();
                  controllers.id = addrJson['address_id'] as int?;

                  controllers.addressController.text = addrJson['address_line_1'] ?? '';
                  controllers.pinCodeController.text = addrJson['pincode'] ?? '';
                  controllers.contactController.text = addrJson['contact_number'] ?? '';
                  controllers.timeZoneController.text = addrJson['time_zone'] ?? '';
                  controllers.country = addrJson['country_name'];
                  controllers.state = addrJson['state_name'];
                  controllers.city = addrJson['city_name'];
                  
                  // Try to find if this matches a registered address in the selected group
                  if (_selectedGroup != null) {
                    controllers.selectedRegisteredAddress = _selectedGroup!.addresses
                        .where((a) => a.companyId == addrJson['company_id'])
                        .firstOrNull;
                  }
                  
                  _addressRows.add(controllers);
                }

              });
            }
          } catch (e) {
            debugPrint('Error fetching plant addresses: $e');
          }
        }
      }

    }
  }

  void _onCompanyChanged(CompanyGroup? group) {
    if (_selectedGroup == group) return;

    setState(() {
      _selectedGroup = group;
      _companyNameController.text = group?.name ?? '';

      for (var row in _addressRows) {
        // ALWAYS clear selectedRegisteredAddress because it belongs to the PREVIOUS company.
        row.selectedRegisteredAddress = null;

        // Only clear the actual text fields if we are creating a NEW site.
        // If we are EDITING, we want to keep the physical location text.
        if (widget.initialSite == null) {
          row.addressController.clear();
          row.pinCodeController.clear();
          row.contactController.clear();
          row.country = null;
          row.state = null;
          row.city = null;
        }
      }

      // For NEW sites, if the company has exactly one address, auto-select it.
      if (widget.initialSite == null &&
          group != null &&
          group.addresses.length == 1 &&
          _addressRows.isNotEmpty) {
        _addressRows.first.updateFromRegistered(group.addresses.first);
      }
    });
  }

  void _addAddressRow() {
    setState(() {
      final newRow = AddressControllers();
      // If we have an existing row, maybe default the timezone?
      if (_addressRows.isNotEmpty) {
        newRow.timeZoneController.text = _addressRows.first.timeZoneController.text;
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
    if (_nameController.text.isEmpty || _selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Site Name and select a Company'),
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
      // Determine correct company_id:
      // 1. Explicitly selected branch address
      // 2. Or, if we are editing and the group matches the site's current company group,
      //    use the site's current companyId to preserve the specific branch.
      // 3. Fallback to the first address in the selected group.
      int? resolvedCompanyId = row.selectedRegisteredAddress?.companyId;

      if (resolvedCompanyId == null &&
          widget.initialSite != null &&
          _selectedGroup != null) {
        // Search if initial site belongs to this group
        final belongsToGroup = _selectedGroup!.addresses.any(
          (a) => a.companyId == widget.initialSite!.companyId,
        );
        if (belongsToGroup) {
          resolvedCompanyId = widget.initialSite!.companyId;
        }
      }

      resolvedCompanyId ??= _selectedGroup?.addresses.firstOrNull?.companyId;

      return CompanyAddress(
        id: row.id,
        addressLine1: row.addressController.text,
        pincode: row.pinCodeController.text,
        country: row.country ?? '',
        state: row.state ?? '',
        city: row.city ?? '',
        contactNumber: row.contactController.text,
        status: _status,
        companyId: resolvedCompanyId,
        timeZone: row.timeZoneController.text.isNotEmpty
            ? row.timeZoneController.text
            : null,

      );

    }).toList();

    final primaryCompanyId = addresses.first.companyId;

    if (primaryCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid company location')),
      );
      return;
    }

    final request = SiteCreateRequest(
      name: _nameController.text,
      orgCode: '', // Removed from UI
      companyId: primaryCompanyId,
      city: _addressRows.first.city,
      timeZone: '--',
      addresses: addresses,
      isPartialUpdate: widget.targetAddressId != null,
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

                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'SITE NAME',
                                  AppAutocomplete<SiteAutocompleteInfo>(
                                    controller: _nameController,
                                    hint: 'e.g. South Site Unit A',
                                    displayStringForOption: (site) =>
                                        site.siteName,
                                    subtitleBuilder: (site) =>
                                        site.companyName ?? '',
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
                                        if (_addressRows.isNotEmpty) {
                                          final row = _addressRows.first;

                                          // Also select the company and registered address if available
                                          if (site.companyId != null) {
                                            final group = _companyGroups
                                                .where(
                                                  (g) => g.addresses.any(
                                                    (a) =>
                                                        a.companyId ==
                                                        site.companyId,
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
                                                            site.companyId,
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
                                child: _buildLabelField(
                                  'SELECT COMPANY',
                                  _isLoadingCompanies
                                      ? const LinearProgressIndicator(
                                          minHeight: 2,
                                        )
                                      : (ref.watch(userRoleProvider).value == UserRole.superAdmin)
                                          ? AppDropdown<CompanyGroup>(
                                              value: _selectedGroup,
                                              items: _companyGroups,
                                              hint: 'Select Company',
                                              itemLabel: (g) => g.name,
                                              onChanged: _onCompanyChanged,
                                            )
                                          : AppTextField(
                                              readOnly: true,
                                              controller: _companyNameController,
                                              hint: 'Company',
                                            ),
                                ),
                              ),
                            ],
                          ),




                          const SizedBox(height: 32),

                          // Section: Location Details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [],
                              ),
                              TextButton.icon(
                                onPressed: _addAddressRow,

                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'ADD NEW ADDRESS',
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
                                backgroundColor: const Color(0xFF141E7A),
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
              widget.initialSite != null
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
                  'ADDRESS',
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
          _buildLabelField(
            'CONTACT NUMBER',
            AppTextField(
              controller: controllers.contactController,
              hint: 'e.g. +1 234 567 8900',
            ),
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
          const SizedBox(height: 24),
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
        // If text is empty and we have an initial value in controller, show all or filtered?
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
    _nameController.dispose();
    _companyNameController.dispose();
    for (var controllers in _addressRows) {

      controllers.dispose();
    }
    super.dispose();
  }
}
