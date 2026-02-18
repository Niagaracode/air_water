import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/device_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../controller/device_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/utils/time_zones.dart';

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

      // Attempt to handle initial plant if possible, though we might need to fetch it
      // For now, siteId and companyId are preserved from widget.device in _save
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
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        child: Container(
          width: 500,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(32),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADD NEW DEVICE',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLabelField(
                            'Enter Device ID*',
                            AppTextField(
                              controller: _deviceIdController,
                              hint: 'Enter Device ID',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'Category*',
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'Unit*',
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
                          const SizedBox(height: 16),
                          _buildLabelField(
                            'Plant Name*',
                            _buildPlantAutocomplete(),
                          ),
                          const SizedBox(height: 16),
                          _buildLabelField(
                            'Tank Name',
                            _buildTankAutocomplete(),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLabelField(
                                  'Sim Number',
                                  AppTextField(
                                    controller: _simNumberController,
                                    hint: 'Enter Sim Number',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildLabelField(
                                  'Time Zone',
                                  _buildTimeZoneAutocomplete(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabelField(
                            'Notes',
                            AppTextField(
                              controller: _notesController,
                              hint: 'Enter Notes',
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabelField(
                            'Status*',
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Radio<int>(
                                      value: 1,
                                      groupValue: _status,
                                      activeColor: const Color(0xFF1B1B4B),
                                      onChanged: (v) =>
                                          setState(() => _status = v!),
                                    ),
                                    const Text('Active'),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Row(
                                  children: [
                                    Radio<int>(
                                      value: 0,
                                      groupValue: _status,
                                      activeColor: const Color(0xFF1B1B4B),
                                      onChanged: (v) =>
                                          setState(() => _status = v!),
                                    ),
                                    const Text('Inactive'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: deviceState.isProcessing ? null : _save,
                      child: deviceState.isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SAVE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              if (deviceState.isProcessing)
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
