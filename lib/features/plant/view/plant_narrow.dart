import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_search_input.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_table.dart';
import '../controller/plant_provider.dart';
import 'add_plant_modal.dart';
import '../model/plant_model.dart';

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
          children: [
            const Text(
              'PLANT MANAGEMENT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppSearchInput(
              controller: _plantSearchController,
              hint: 'Search...',
              onChanged: (v) => plantNotifier.loadPlants(search: v),
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
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AddPlantModal(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B1B4B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('ADD +'),
            ),
            const SizedBox(height: 16),
            AppTable(
              headers: const ['SI.NO', 'City', 'Status'],
              itemCount: plantState.plants.length,
              isLoading: plantState.isLoading,
              hasMore: plantState.hasMore,
              onLoadMore: () =>
                  plantNotifier.loadMore(search: _plantSearchController.text),
              itemBuilder: (context, index) {
                final Plant item = plantState.plants[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text((index + 1).toString().padLeft(2, '0')),
                      ),
                      Expanded(child: Text(item.name)),
                      Expanded(child: Text(item.statusText)),
                    ],
                  ),
                );
              },
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
