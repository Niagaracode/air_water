import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../tank/presentation/controller/tank_provider.dart';
import '../../data/tank_dimension_model.dart';
import '../../provider/tank_dimension_provider.dart';

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
  String? selectedType;
  List<String> tankTypes = [
    'Horizontal Cylindrical',
    'Vertical Cylindrical',
    'Spherical',
    'Rectangular',
    'Box Cylinder',
    'Round Tank',
  ];
  bool isLoadingTypes = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.tankDimension.name);
    selectedType = widget.tankDimension.type.isNotEmpty ? widget.tankDimension.type : null;
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
        final fetchedTypes = rawList
            .map((item) {
              if (item is Map && item['name'] != null) {
                return item['name'].toString();
              }
              return item.toString();
            })
            .where((t) => t.isNotEmpty)
            .toList();

        if (fetchedTypes.isNotEmpty) {
          final uniqueTypes = <String>{...tankTypes, ...fetchedTypes}.toList();
          setState(() {
            tankTypes = uniqueTypes;
            if (selectedType != null && !tankTypes.contains(selectedType)) {
              tankTypes.add(selectedType!);
            }
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

    if (selectedType == null || selectedType!.trim().isEmpty) {
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
      final data = {
        'name': name,
        'type': selectedType!.trim(),
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

            /// CARD FORM
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              label: "Name *",
                              child: AppTextField(
                                controller: nameCtrl,
                                hint: "Enter dimension name",
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: "Type *",
                              child: AppDropdown<String?>(
                                value: selectedType,
                                items: [null, ...tankTypes],
                                itemLabel: (v) => v ?? 'Select Type',
                                hint: 'Select Type',
                                onChanged: (value) {
                                  setState(() {
                                    selectedType = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: "Max Overflow *",
                              child: AppTextField(
                                controller: maxOverflowCtrl,
                                hint: "Enter max overflow",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
    return Column(
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
    );
  }
}
