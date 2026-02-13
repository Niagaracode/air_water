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

class PlantWide extends ConsumerStatefulWidget {
  const PlantWide({super.key});

  @override
  ConsumerState<PlantWide> createState() => _PlantWideState();
}

class _PlantWideState extends ConsumerState<PlantWide> {
  final _plantSearchController = TextEditingController();
  Timer? _debounce;
  String? _hoveredOrgCode;

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildManagementCard(plantState, plantNotifier)],
        ),
      ),
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing  ${state.totalEntries} entries',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          _buildGroupedTable(state, notifier),
          if (state.hasMore && state.groupedPlants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => notifier.loadMoreGrouped(),
                        child: const Text('Load More'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(PlantNotifier notifier) {
    final state = ref.watch(plantNotifierProvider);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextField(
            controller: _plantSearchController,
            hint: 'Search By Plant',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppDropdown<int>(
            value: state.selectedStatus,
            items: const [1, 0],
            hint: 'Status',
            itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
            onChanged: (v) => notifier.setStatus(v),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppDatePickerField(
            selectedDate: state.selectedDate != null
                ? DateTime.parse(state.selectedDate!)
                : null,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            onDateChanged: (date) {
              if (date != null) {
                final formatted =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                notifier.setDate(formatted);
              } else {
                notifier.setDate(null);
              }
            },
          ),
        ),
        const SizedBox(width: 32),
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
                        CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                      ),
                  child: child,
                );
              },
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('ADD'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryDeep,
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

  Widget _buildGroupedTable(PlantState state, PlantNotifier notifier) {
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
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  child: Row(
                    children: [
                      _tableHeaderCell('SI.NO', width: 70),
                      _tableHeaderCell('City', flex: 2),
                      _tableHeaderCell('Date', flex: 2),
                      _tableHeaderCell('Company', flex: 2),
                      _tableHeaderCell('State', flex: 2),
                      _tableHeaderCell('Country', flex: 2),
                      _tableHeaderCell('Status', flex: 2),
                      _tableHeaderCell('Address', flex: 3),
                    ],
                  ),
                ),
                // Table body
                if (state.groupedPlants.isEmpty && !state.isLoading)
                  Container(
                    padding: const EdgeInsets.all(48),
                    alignment: Alignment.center,
                    child: const Text(
                      'No record found',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                else
                  ...List.generate(state.groupedPlants.length, (index) {
                    final group = state.groupedPlants[index];
                    final orgCode =
                        group.plantOrganizationCode ?? 'unknown_$index';
                    final isExpanded = state.expandedGroups.contains(orgCode);

                    return _buildGroupSection(
                      index: index,
                      group: group,
                      orgCode: orgCode,
                      isExpanded: isExpanded,
                      notifier: notifier,
                      isLast: index == state.groupedPlants.length - 1,
                    );
                  }),
                if (state.isLoading && state.groupedPlants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
        if (state.isLoading && state.groupedPlants.isNotEmpty)
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

  Widget _tableHeaderCell(String text, {double? width, int? flex}) {
    final child = Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    );
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex ?? 1, child: child);
  }

  Widget _buildGroupSection({
    required int index,
    required PlantGroup group,
    required String orgCode,
    required bool isExpanded,
    required PlantNotifier notifier,
    required bool isLast,
  }) {
    return Column(
      children: [
        if (index > 0) Divider(height: 1, color: Colors.grey.shade200),
        // Group header row (plant name row)
        MouseRegion(
          onEnter: (_) {
            setState(() => _hoveredOrgCode = orgCode);
            if (!isExpanded) notifier.toggleGroup(orgCode);
          },
          onExit: (_) => setState(() => _hoveredOrgCode = null),
          child: InkWell(
            onTap: () => notifier.toggleGroup(orgCode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const Expanded(flex: 2, child: SizedBox()), // Align with Date
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ), // Align with Company
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ), // Align with State
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ), // Align with Country
                  const Expanded(
                    flex: 2,
                    child: SizedBox(),
                  ), // Align with Status
                  Expanded(
                    flex: 3, // Align with Address
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Visibility(
                        visible: _hoveredOrgCode == orgCode || isExpanded,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Address rows (visible when expanded)
        if (isExpanded)
          ...group.addresses.map((addr) {
            return Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade100),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 70),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.city ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.createdAt?.split('T').first ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.companyName ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              addr.companyFullAddress,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.state ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.country ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: addr.status == 1
                                  ? Colors.green
                                  : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              addr.statusText,
                              style: TextStyle(
                                color: addr.status == 1
                                    ? Colors.green
                                    : Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.fullAddress,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
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
}
