import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_search_input.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../controller/plant_provider.dart';
import 'add_plant_modal.dart';

class PlantNarrow extends ConsumerStatefulWidget {
  const PlantNarrow({super.key});

  @override
  ConsumerState<PlantNarrow> createState() => _PlantNarrowState();
}

class _PlantNarrowState extends ConsumerState<PlantNarrow> {
  final _plantSearchController = TextEditingController();
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final plantState = ref.watch(plantNotifierProvider);
    final plantNotifier = ref.read(plantNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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
            AppSearchInput(
              controller: _plantSearchController,
              hint: 'Search...',
              onChanged: (v) => plantNotifier.loadGroupedPlants(name: v),
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              value: _selectedStatus,
              items: const ['Active', 'Inactive'],
              hint: 'Status',
              itemLabel: (v) => v,
              onChanged: (v) => setState(() => _selectedStatus = v),
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
                  pageBuilder: (context, anim1, anim2) =>
                      const AddPlantModal(),
                  transitionBuilder: (context, anim1, anim2, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim1,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    );
                  },
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ADD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1B4B),
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
                          onPressed: () => plantNotifier.loadMoreGrouped(
                            name: _plantSearchController.text,
                          ),
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
    return Container(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: const Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'SI.NO',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'City',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Status',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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
                final isExpanded =
                    plantState.expandedGroups.contains(orgCode);

                return Column(
                  children: [
                    if (index > 0)
                      Divider(height: 1, color: Colors.grey.shade200),
                    // Group header
                    InkWell(
                      onTap: () => notifier.toggleGroup(orgCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Address rows
                    if (isExpanded)
                      ...group.addresses.map((addr) {
                        return Column(
                          children: [
                            Divider(
                                height: 1, color: Colors.grey.shade100),
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
                                    child: Text(
                                      addr.city ?? '',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: addr.status == 1
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          addr.statusText,
                                          style: TextStyle(
                                            color: addr.status == 1
                                                ? Colors.green
                                                : Colors.grey,
                                            fontSize: 11,
                                          ),
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
              }),
            if (plantState.isLoading && plantState.groupedPlants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _plantSearchController.dispose();
    super.dispose();
  }
}
