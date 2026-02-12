import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_search_input.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_table.dart';
import '../controller/plant_provider.dart';
import 'add_plant_modal.dart';
import '../model/plant_model.dart';

class PlantMiddle extends ConsumerStatefulWidget {
  const PlantMiddle({super.key});

  @override
  ConsumerState<PlantMiddle> createState() => _PlantMiddleState();
}

class _PlantMiddleState extends ConsumerState<PlantMiddle> {
  final _plantSearchController = TextEditingController();
  final _companySearchController = TextEditingController();
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final plantState = ref.watch(plantNotifierProvider);
    final plantNotifier = ref.read(plantNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard >> Plant',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildManagementCard(plantState, plantNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(PlantState state, PlantNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLANT MANAGEMENT',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildFilters(notifier),
          const SizedBox(height: 20),
          AppTable(
            headers: const [
              'SI.NO',
              'Plant Name',
              'Created At',
              'State',
              'Status',
            ],
            itemCount: state.plants.length,
            isLoading: state.isLoading,
            hasMore: state.hasMore,
            onLoadMore: () =>
                notifier.loadMore(search: _plantSearchController.text),
            itemBuilder: (context, index) {
              final Plant item = state.plants[index];
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
                    Expanded(child: Text(item.createdAt ?? '')),
                    Expanded(child: Text(item.stateName ?? '')),
                    Expanded(child: Text(item.statusText)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(PlantNotifier notifier) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 200,
          child: AppSearchInput(
            controller: _plantSearchController,
            hint: 'Search By Plant',
            onChanged: (v) => notifier.loadPlants(search: v),
          ),
        ),
        SizedBox(
          width: 200,
          child: AppSearchInput(
            controller: _companySearchController,
            hint: 'Search By Company',
          ),
        ),
        SizedBox(
          width: 150,
          child: AppDropdown<String>(
            value: _selectedStatus,
            items: const ['Active', 'Inactive'],
            hint: 'Status',
            itemLabel: (v) => v,
            onChanged: (v) => setState(() => _selectedStatus = v),
          ),
        ),
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
          ),
          child: const Text('ADD +'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _plantSearchController.dispose();
    _companySearchController.dispose();
    super.dispose();
  }
}
