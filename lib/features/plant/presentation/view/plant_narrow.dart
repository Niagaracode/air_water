import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/plant_provider.dart';
import '../widgets/add_plant_modal.dart';
import '../model/plant_model.dart';
import 'dart:async';

class PlantNarrow extends ConsumerStatefulWidget {
  const PlantNarrow({super.key});

  @override
  ConsumerState<PlantNarrow> createState() => _PlantNarrowState();
}

class _PlantNarrowState extends ConsumerState<PlantNarrow> {
  final _plantSearchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _plantSearchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        ref
            .read(plantNotifierProvider.notifier)
            .setSearchName(_plantSearchController.text);
      }
    });
  }

  @override
  void dispose() {
    _plantSearchController.removeListener(_onSearchChanged);
    _plantSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plantState = ref.watch(plantNotifierProvider);
    final plantNotifier = ref.read(plantNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: cardBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PLANT MANAGEMENT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _plantSearchController, hint: 'Search...'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppDropdown<int>(
                    value: plantState.selectedStatus,
                    items: const [1, 0],
                    hint: 'Status',
                    itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
                    onChanged: (v) => plantNotifier.setStatus(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppDatePickerField(
                    selectedDate: plantState.selectedDate != null
                        ? DateTime.parse(plantState.selectedDate!)
                        : null,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (date) {
                      if (date != null) {
                        final formatted =
                            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        plantNotifier.setDate(formatted);
                      } else {
                        plantNotifier.setDate(null);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'AddPlant',
                  barrierColor: Colors.black54,
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, anim1, anim2) => const AddPlantModal(),
                  transitionBuilder: (context, anim1, anim2, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim1,
                              curve: Curves.easeOut,
                            ),
                          ),
                      child: child,
                    );
                  },
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ADD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDeep,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Showing  ${plantState.totalEntries} entries',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            _buildGroupedTable(plantState, plantNotifier),
            if (plantState.hasMore && plantState.groupedPlants.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: plantState.isLoading
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: () => plantNotifier.loadMoreGrouped(),
                          child: const Text('Load More'),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTable(PlantState plantState, PlantNotifier notifier) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'SI.NO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'City',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table body
                if (plantState.groupedPlants.isEmpty && !plantState.isLoading)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Text(
                      'No record found',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                else
                  ...List.generate(plantState.groupedPlants.length, (index) {
                    final group = plantState.groupedPlants[index];
                    final orgCode =
                        group.plantOrganizationCode ?? 'unknown_$index';
                    final isExpanded = plantState.expandedGroups.contains(
                      orgCode,
                    );

                    return _buildGroupSection(
                      index: index,
                      group: group,
                      orgCode: orgCode,
                      isExpanded: isExpanded,
                      notifier: notifier,
                    );
                  }),
                if (plantState.isLoading && plantState.groupedPlants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
        if (plantState.isLoading && plantState.groupedPlants.isNotEmpty)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupSection({
    required int index,
    required PlantGroup group,
    required String orgCode,
    required bool isExpanded,
    required PlantNotifier notifier,
  }) {
    return Column(
      children: [
        if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
        // Group header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Address rows
        if (isExpanded)
          ...group.addresses.map((addr) {
            return Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade100),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.plantLocation,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${addr.companyName ?? ''} (${addr.companyCity ?? ''}, ${addr.companyCountry ?? ''})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 16,
                              ),
                              onPressed: () => _showEditModal(group, addr),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red.shade400,
                                size: 16,
                              ),
                              onPressed: () => _showDeleteDialog(addr),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
      ],
    );
  }

  void _showEditModal(PlantGroup group, PlantGroupAddress addr) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) {
        return AddPlantModal(initialPlant: addr);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  Future<void> _showDeleteDialog(PlantGroupAddress addr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plant'),
        content: Text(
          'Are you sure you want to delete "${addr.plantName}" at "${addr.city}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && addr.plantId != null) {
      final success = await ref
          .read(plantNotifierProvider.notifier)
          .deletePlant(addr.plantId!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant deleted successfully')),
        );
      }
    }
  }
}
