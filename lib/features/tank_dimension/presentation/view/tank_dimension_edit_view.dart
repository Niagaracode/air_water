import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
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
  late TextEditingController typeCtrl;
  late TextEditingController canLengthCtrl;
  late TextEditingController diameterCtrl;
  late TextEditingController dishDepthCtrl;
  late TextEditingController maxOverflowCtrl;
  late TextEditingController descCtrl;
  String? selectedUnit;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    typeCtrl = TextEditingController(text: widget.tankDimension.type);
    
    // Initialize selectedUnit from the allowed options
    final initialUnit = widget.tankDimension.unitOfMeasures.trim();
    const allowedUnits = ['cm', 'ft', 'in', 'm', 'mm', 'yd'];
    if (allowedUnits.contains(initialUnit)) {
      selectedUnit = initialUnit;
    } else {
      selectedUnit = null;
    }

    canLengthCtrl = TextEditingController(text: widget.tankDimension.canLength.toString());
    diameterCtrl = TextEditingController(text: widget.tankDimension.diameter.toString());
    dishDepthCtrl = TextEditingController(text: widget.tankDimension.dishDepth.toString());
    maxOverflowCtrl = TextEditingController(text: widget.tankDimension.maxOverflow.toString());
    descCtrl = TextEditingController(text: widget.tankDimension.description);
  }

  @override
  void dispose() {
    typeCtrl.dispose();
    canLengthCtrl.dispose();
    diameterCtrl.dispose();
    dishDepthCtrl.dispose();
    maxOverflowCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (typeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Type is required"),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final data = {
        'type': typeCtrl.text.trim(),
        'unit_of_measures': selectedUnit ?? '',
        'can_length': double.tryParse(canLengthCtrl.text.trim()) ?? 0.0,
        'diameter': double.tryParse(diameterCtrl.text.trim()) ?? 0.0,
        'dish_depth': double.tryParse(dishDepthCtrl.text.trim()) ?? 0.0,
        'max_overflow': double.tryParse(maxOverflowCtrl.text.trim()) ?? 0.0,
        'description': descCtrl.text.trim(),
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
                const Text(
                  "Tank Dimension Information",
                  style: TextStyle(
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
                        children: [
                          Expanded(
                            child: _field(
                              label: "Type *",
                              child: AppTextField(
                                controller: typeCtrl,
                                hint: "Enter type",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: "Unit of Measures",
                              child: AppDropdown<String?>(
                                value: selectedUnit,
                                items: const [null, 'cm', 'ft', 'in', 'm', 'mm', 'yd'],
                                itemLabel: (v) => v ?? 'Select',
                                hint: 'Select',
                                onChanged: (value) {
                                  setState(() {
                                    selectedUnit = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: "Can Length",
                              child: AppTextField(
                                controller: canLengthCtrl,
                                hint: "Enter can length",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: "Max Overflow",
                              child: AppTextField(
                                controller: maxOverflowCtrl,
                                hint: "Enter max overflow",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: "Diameter",
                              child: AppTextField(
                                controller: diameterCtrl,
                                hint: "Enter diameter",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _field(
                              label: "Dish Depth",
                              child: AppTextField(
                                controller: dishDepthCtrl,
                                hint: "Enter dish depth",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: "Description",
                              child: AppTextField(
                                controller: descCtrl,
                                hint: "Enter description",
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
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
