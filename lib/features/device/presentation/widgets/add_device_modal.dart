import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/device_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../controller/device_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/utils/time_zones.dart';
import '../widgets/map_picker_dialog.dart';
import '../../../../shared/widgets/app_autocomplete.dart';

import 'package:google_fonts/google_fonts.dart';

class AddDeviceModal extends ConsumerStatefulWidget {
  final Device? device;
  const AddDeviceModal({super.key, this.device});

  @override
  ConsumerState<AddDeviceModal> createState() => _AddDeviceModalState();
}

class _AddDeviceModalState extends ConsumerState<AddDeviceModal> {
  final _deviceIdController = TextEditingController();
  final _notesController = TextEditingController();
  final _simNumberController = TextEditingController();
  final _plantAutocompleteController = TextEditingController();
  final _tankAutocompleteController = TextEditingController();
  final _timeZoneController = TextEditingController();

  PlantAutocompleteInfo? _selectedPlant;
  int? _selectedTankId;
  Map<String, dynamic>? _dropdownData;
  bool _isLoadingDropdowns = false;

  dynamic _selectedCategory;
  dynamic _selectedUnit;
  int _status = 1;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      _deviceIdController.text = widget.device!.deviceId;
      _notesController.text = widget.device!.notes ?? '';
      _simNumberController.text = widget.device!.simNumber ?? '';
      _plantAutocompleteController.text = widget.device!.siteName ?? '';
      _tankAutocompleteController.text = widget.device!.tankName ?? '';
      _timeZoneController.text = widget.device!.timeZone ?? '';
      _status = widget.device!.status;
      _selectedTankId = widget.device!.tankId;
      _latitude = widget.device!.latitude;
      _longitude = widget.device!.longitude;
    }
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    setState(() => _isLoadingDropdowns = true);
    try {
      final data = await ref.read(deviceProvider.notifier).getDeviceDropdowns();
      setState(() {
        _dropdownData = data;
        if (widget.device != null) {
          _selectedCategory = (data['categories'] as List).firstWhere(
                (c) => c['id'] == widget.device!.category,
            orElse: () => null,
          );
          _selectedUnit = (data['units'] as List).firstWhere(
                (u) => u['id'].toString() == widget.device!.unitId,
            orElse: () => null,
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading dropdowns: $e');
    } finally {
      setState(() => _isLoadingDropdowns = false);
    }
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _notesController.dispose();
    _simNumberController.dispose();
    _plantAutocompleteController.dispose();
    _tankAutocompleteController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_deviceIdController.text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Device ID is required')),
      );
      return;
    }

    if (_selectedCategory == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Category')),
      );
      return;
    }

    if (_selectedUnit == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a Unit')),
      );
      return;
    }

    if (_selectedTankId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Invalid Tank')));
      return;
    }

    final request = DeviceCreateRequest(
      deviceId: _deviceIdController.text,
      notes: _notesController.text,
      simNumber: _simNumberController.text,
      category: _selectedCategory is String
          ? _selectedCategory
          : _selectedCategory['id'],
      timeZone: _timeZoneController.text,
      siteId: _selectedPlant?.plantId ?? widget.device?.siteId,
      companyId: _selectedPlant?.companyId ?? widget.device?.companyId,
      tankId: _selectedTankId,
      unitId: _selectedUnit['id'].toString(),
      status: _status,
      latitude: _latitude,
      longitude: _longitude,
    );

    final success = widget.device != null
        ? await ref
        .read(deviceProvider.notifier)
        .updateDevice(widget.device!.id, request)
        : await ref.read(deviceProvider.notifier).createDevice(request);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);

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
                      // Header with close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.device != null
                                      ? 'Edit Device'
                                      : 'Create New Device',
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Configure device settings and network association.',
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

                      _buildLabelField(
                        'DEVICE IDENTIFIER',
                        AppAutocomplete<String>(
                          controller: _deviceIdController,
                          hint: 'Enter Unique Device ID',
                          optionsBuilder: (textEditingValue) async {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            return await ref
                                .read(deviceProvider.notifier)
                                .getDeviceNameSuggestions(
                              textEditingValue.text,
                            );
                          },
                          displayStringForOption: (option) => option,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLabelField(
                              'CATEGORY',
                              _isLoadingDropdowns
                                  ? const LinearProgressIndicator(
                                minHeight: 2,
                              )
                                  : AppDropdown<dynamic>(
                                value: _selectedCategory,
                                items:
                                _dropdownData?['categories'] ??
                                    [],
                                itemLabel: (v) => v['name'],
                                hint: 'Select Category',
                                onChanged: (v) => setState(
                                      () => _selectedCategory = v,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildLabelField(
                              'MEASUREMENT UNIT',
                              _isLoadingDropdowns
                                  ? const LinearProgressIndicator(
                                minHeight: 2,
                              )
                                  : AppDropdown<dynamic>(
                                value: _selectedUnit,
                                items: _dropdownData?['units'] ?? [],
                                itemLabel: (u) => u['name'],
                                hint: 'Select Unit',
                                onChanged: (v) =>
                                    setState(() => _selectedUnit = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildLabelField(
                        'PLANT ASSOCIATION',
                        _buildPlantAutocomplete(),
                      ),
                      const SizedBox(height: 32),
                      _buildLabelField(
                        'ASSIGNED TANK',
                        _buildTankAutocomplete(),
                      ),
                      const SizedBox(height: 40),

                      // Section: Network & Location
                      Row(
                        children: [
                          const Icon(
                            Icons.hub_rounded,
                            size: 18,
                            color: Color(0xFF141E7A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'NETWORK & LOCATION',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF141E7A),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 32,
                        thickness: 1,
                        color: Color(0xFFF3F4F6),
                      ),

                      _buildLabelField(
                        'SIM CARD NUMBER',
                        AppTextField(
                          controller: _simNumberController,
                          hint: 'Enter ICCID / Sim Number',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectedPlant == null
                                  ? null
                                  : _pickLocation,
                              icon: const Icon(
                                Icons.location_on_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _latitude != null
                                    ? 'Location Set (${_latitude!.toStringAsFixed(4)})'
                                    : 'Map Location',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: _latitude != null
                                      ? const Color(0xFF141E7A)
                                      : const Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_latitude != null) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => setState(() {
                                _latitude = null;
                                _longitude = null;
                              }),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildLabelField(
                        'TIME ZONE REGION',
                        _buildTimeZoneAutocomplete(),
                      ),
                      const SizedBox(height: 40),

                      // Section: Additional Info
                      Row(
                        children: [
                          const Icon(
                            Icons.note_alt_rounded,
                            size: 18,
                            color: Color(0xFF141E7A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ADDITIONAL INFORMATION',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF141E7A),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 32,
                        thickness: 1,
                        color: Color(0xFFF3F4F6),
                      ),

                      _buildLabelField(
                        'CONFIGURATION NOTES',
                        AppTextField(
                          controller: _notesController,
                          hint: 'Enter technical notes...',
                          maxLines: 3,
                        ),
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
                                  'DEVICE STATUS',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: const Color(0xFF141E7A),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Enable or disable this device.',
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
                          onPressed: deviceState.isProcessing
                              ? null
                              : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF141E7A),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: deviceState.isProcessing
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : Text(
                            widget.device != null
                                ? 'UPDATE DEVICE'
                                : 'REGISTER DEVICE',
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
                if (deviceState.isProcessing)
            Positioned.fill(  child: Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            ),
                    ],
                  ),
                ),
                  ],
                ),
            ),
        ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) => MapPickerDialog(
        initialAddress: _selectedPlant?.fullAddress,
        initialLocation: _latitude != null && _longitude != null
            ? LatLng(_latitude!, _longitude!)
            : null,
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Widget _buildTimeZoneAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _timeZoneController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return TimeZoneUtils.ianaTimeZones.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          displayStringForOption: (String option) => option,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search Time Zone (e.g. Asia/Kolkata)',
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
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
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

  Widget _buildTankAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Map<String, dynamic>>(
          textEditingController: _tankAutocompleteController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            return await ref
                .read(deviceProvider.notifier)
                .searchTanks(
              textEditingValue.text,
              plantId: _selectedPlant?.plantId ?? widget.device?.siteId,
            );
          },
          displayStringForOption: (Map<String, dynamic> option) =>
          option['tank_number'],
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search Tank by Name',
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: options.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No search found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option['tank_number'],
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          onSelected(option);
                          setState(
                                () => _selectedTankId = option['tank_id'],
                          );
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

  Widget _buildPlantAutocomplete() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<PlantAutocompleteInfo>(
          textEditingController: _plantAutocompleteController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<PlantAutocompleteInfo>.empty();
            }
            return await ref
                .read(deviceProvider.notifier)
                .searchPlants(textEditingValue.text);
          },
          displayStringForOption: (PlantAutocompleteInfo option) =>
          option.displayName ?? option.plantName,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Search Plant by Name',
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          option.displayName ??
                              '${option.plantName} ${option.fullAddress}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          onSelected(option);
                          setState(() => _selectedPlant = option);
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

  Widget _buildLabelField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        const SizedBox(height: 6),
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

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info, color: Color(0xFF1B1B4B), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enter Device Details To Configure And Add A New Device.',
              style: TextStyle(color: Color(0xFF1B1B4B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}