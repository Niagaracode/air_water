import 'dart:typed_data';
import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../data/tank_dimension_model.dart';
import '../../provider/tank_dimension_provider.dart';

class TankTypeOption {
  final dynamic id;
  final String name;

  const TankTypeOption({required this.id, required this.name});
}

class TankDimensionEditView extends ConsumerStatefulWidget {
  final TankDimension tankDimension;
  final bool showViewList;

  const TankDimensionEditView({
    super.key,
    required this.tankDimension,
    this.showViewList = true,
  });

  @override
  ConsumerState<TankDimensionEditView> createState() => _TankDimensionEditViewState();
}

class _TankDimensionEditViewState extends ConsumerState<TankDimensionEditView> {
  late TextEditingController nameCtrl;
  late TextEditingController maxOverflowCtrl;
  dynamic selectedTypeId;

  List<TankTypeOption> tankTypeOptions = [
    const TankTypeOption(id: 1, name: 'Horizontal Cylindrical'),
    const TankTypeOption(id: 2, name: 'Vertical Cylindrical'),
    const TankTypeOption(id: 3, name: 'Spherical'),
    const TankTypeOption(id: 4, name: 'Rectangular'),
    const TankTypeOption(id: 5, name: 'Box Cylinder'),
    const TankTypeOption(id: 6, name: 'Round Tank'),
  ];

  bool isLoadingTypes = false;
  bool isSaving = false;

  // Chart Data file upload state (UI display only, not sent to backend)
  String? chartFileName;
  Uint8List? chartFileBytes;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.tankDimension.name);

    final initialType = widget.tankDimension.type.trim();
    final initialTypeName = widget.tankDimension.typeName.trim();

    if (initialType.isNotEmpty) {
      final parsedId = int.tryParse(initialType) ?? initialType;
      selectedTypeId = parsedId;

      final label = initialTypeName.isNotEmpty ? initialTypeName : initialType;
      if (!tankTypeOptions.any((t) => t.id.toString() == initialType.toString())) {
        tankTypeOptions.add(TankTypeOption(id: parsedId, name: label));
      }
    } else {
      selectedTypeId = null;
    }

    maxOverflowCtrl = TextEditingController(
      text: widget.tankDimension.id == 0 && widget.tankDimension.maxOverflow == 0.0
          ? ''
          : widget.tankDimension.maxOverflow.toString(),
    );

    _loadTankTypes();
  }

  Future<void> _loadTankTypes() async {
    setState(() => isLoadingTypes = true);
    try {
      final dropdownData = await ref.read(tankNotifierProvider.notifier).getDropdowns();
      if (dropdownData.containsKey('tank_types') && dropdownData['tank_types'] is List) {
        final List rawList = dropdownData['tank_types'];
        final List<TankTypeOption> fetchedOptions = [];

        for (var item in rawList) {
          if (item is Map && item['id'] != null && item['name'] != null) {
            fetchedOptions.add(TankTypeOption(
              id: item['id'],
              name: item['name'].toString(),
            ));
          }
        }

        if (fetchedOptions.isNotEmpty) {
          final Map<String, TankTypeOption> map = {};
          for (var opt in tankTypeOptions) {
            map[opt.id.toString()] = opt;
          }
          for (var opt in fetchedOptions) {
            map[opt.id.toString()] = opt;
          }
          setState(() {
            tankTypeOptions = map.values.toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading tank types for dropdown: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingTypes = false);
      }
    }
  }

  Future<void> _pickChartFile() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickMedia();
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          chartFileName = file.name;
          chartFileBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking chart file: $e');
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    maxOverflowCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name is required")),
      );
      return;
    }

    if (selectedTypeId == null || selectedTypeId.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Type is required")),
      );
      return;
    }

    final maxOverflowText = maxOverflowCtrl.text.trim();
    if (maxOverflowText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Max Overflow is required")),
      );
      return;
    }

    final maxOverflowVal = double.tryParse(maxOverflowText);
    if (maxOverflowVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number for Max Overflow")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Stores tank_type ID as string into `type` column of `tank_dimension` table
      final data = {
        'name': name,
        'type': selectedTypeId.toString(),
        'max_overflow': maxOverflowVal,
      };

      final notifier = ref.read(tankDimensionNotifierProvider.notifier);
      final success = widget.tankDimension.id == 0
          ? await notifier.createTankDimension(data)
          : await notifier.updateTankDimension(widget.tankDimension.id, data);

      if (!mounted) return;
      setState(() => isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              widget.tankDimension.id == 0
                  ? "Tank dimension created successfully"
                  : "Tank dimension updated successfully",
            ),
          ),
        );
        Navigator.of(context, rootNavigator: true).pop();
      } else {
        final error = ref.read(tankDimensionNotifierProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              error ?? "Failed to save tank dimension",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.tankDimension.id == 0 ? "Create Tank Dimension" : "Edit Tank Dimension",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                )
              ],
            ),
            const SizedBox(height: 16),

            /// CARD FORM - Each field takes its own full-width row
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ROW 1: NAME
                      _field(
                        label: "Name *",
                        child: AppTextField(
                          controller: nameCtrl,
                          hint: "Enter dimension name",
                        ),
                      ),
                      const SizedBox(height: 18),

                      /// ROW 2: TYPE (Stores tank_type ID)
                      _field(
                        label: "Type *",
                        child: AppDropdown<dynamic>(
                          value: selectedTypeId,
                          items: [null, ...tankTypeOptions.map((t) => t.id)],
                          itemLabel: (v) {
                            if (v == null) return 'Select Type';
                            final match = tankTypeOptions.firstWhere(
                              (t) => t.id.toString() == v.toString(),
                              orElse: () => TankTypeOption(id: v, name: v.toString()),
                            );
                            return match.name;
                          },
                          hint: 'Select Type',
                          onChanged: (value) {
                            setState(() {
                              selectedTypeId = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      /// ROW 3: MAX OVERFLOW
                      _field(
                        label: "Max Overflow *",
                        child: AppTextField(
                          controller: maxOverflowCtrl,
                          hint: "Enter max overflow",
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 18),

                      /// ROW 4: CHART DATA FILE UPLOAD (Display only)
                      _field(
                        label: "Chart Data",
                        child: _buildChartFileUploadTile(),
                      ),
                      const SizedBox(height: 32),

                      /// ACTION BUTTONS
                      if (widget.showViewList)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () => _openTankDimensionList(context),
                                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                                  label: const Text("View List"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primary,
                                    side: BorderSide(color: primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text("Save Changes"),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Save Changes"),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CHART DATA FILE UPLOAD TILE (Display Only)
  Widget _buildChartFileUploadTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: chartFileName != null
          ? Row(
              children: [
                Icon(Icons.insert_drive_file_outlined, color: primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chartFileName!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Chart Data file selected",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      chartFileName = null;
                      chartFileBytes = null;
                    });
                  },
                ),
              ],
            )
          : InkWell(
              onTap: _pickChartFile,
              borderRadius: BorderRadius.circular(10),
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(10),
                dashPattern: const [6, 3],
                color: primary.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        "Click to upload Chart Data file",
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _openTankDimensionList(BuildContext context) {
    final router = GoRouter.of(context);

    final rootNav = Navigator.of(context, rootNavigator: true);
    while (rootNav.canPop()) {
      rootNav.pop();
    }

    final localNav = Navigator.of(context);
    while (localNav.canPop()) {
      localNav.pop();
    }

    router.go('/tank-dimension');
  }

  Widget _field({required String label, required Widget child}) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
