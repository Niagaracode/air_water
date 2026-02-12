import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_search_input.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_table.dart';
import '../controller/plant_provider.dart';
import 'add_plant_modal.dart';
import '../model/plant_model.dart';

class PlantWide extends ConsumerStatefulWidget {
  const PlantWide({super.key});

  @override
  ConsumerState<PlantWide> createState() => _PlantWideState();
}

class _PlantWideState extends ConsumerState<PlantWide> {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumbs(),
            const SizedBox(height: 24),
            _buildManagementCard(plantState, plantNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return const Row(
      children: [
        Text('Dashboard', style: TextStyle(color: Colors.grey)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ),
        Text(
          'Plant',
          style: TextStyle(
            color: Color(0xFF5C6AC4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCard(PlantState state, PlantNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLANT MANAGEMENT',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Centralize Plant Information Including Identification, Locations, And Status Management',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          _buildFilterRow(notifier),
          const SizedBox(height: 24),
          AppTable(
            headers: const [
              'SI.NO',
              'City',
              'Date',
              'State',
              'Country',
              'Status',
              'Address',
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
                    Expanded(child: Text(item.countryName ?? '')),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: item.status == 1
                                ? Colors.green
                                : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.statusText,
                            style: TextStyle(
                              color: item.status == 1
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.fullAddress,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.plants.length} entries',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(PlantNotifier notifier) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppSearchInput(
            controller: _plantSearchController,
            hint: 'Search By Plant',
            onChanged: (v) => notifier.loadPlants(search: v),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: AppSearchInput(
            controller: _companySearchController,
            hint: 'Search By Company',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppDropdown<String>(
            value: _selectedStatus,
            items: const ['Active', 'Inactive'],
            hint: 'Status',
            itemLabel: (v) => v,
            onChanged: (v) => setState(() => _selectedStatus = v),
          ),
        ),
        const SizedBox(width: 32),
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddPlantModal(),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('ADD'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B1B4B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
