import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/plant_provider.dart';
import '../widgets/add_plant_modal.dart';
import '../model/plant_model.dart';

class PlantWide extends ConsumerStatefulWidget {
  const PlantWide({super.key});

  @override
  ConsumerState<PlantWide> createState() => _PlantWideState();
}

class _PlantWideState extends ConsumerState<PlantWide> {
  final _plantSearchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(plantNotifierProvider.notifier).loadMoreGrouped();
    }
  }

  @override
  void dispose() {
    _plantSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plantState = ref.watch(plantNotifierProvider);
    final plantNotifier = ref.read(plantNotifierProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverToBoxAdapter(
              child: _buildHeader(plantState, plantNotifier),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: _buildVirtualizedTable(plantState, plantNotifier),
          ),
          if (plantState.isLoading && plantState.groupedPlants.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(PlantState state, PlantNotifier notifier) {
    return Column(
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
      ],
    );
  }

  Widget _buildFilterRow(PlantNotifier notifier) {
    final state = ref.watch(plantNotifierProvider);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: RawAutocomplete<PlantAutocompleteInfo>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<PlantAutocompleteInfo>.empty();
              }
              return await notifier.searchPlants(textEditingValue.text);
            },
            displayStringForOption: (PlantAutocompleteInfo option) =>
                option.plantName,
            onSelected: (PlantAutocompleteInfo selection) {
              _plantSearchController.text = selection.plantName;
              notifier.setSearchName(selection.plantName);
              notifier.loadGroupedPlants();
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  if (_plantSearchController.text != controller.text &&
                      _plantSearchController.text.isNotEmpty &&
                      controller.text.isEmpty) {
                    controller.text = _plantSearchController.text;
                  }

                  return AppTextField(
                    controller: controller,
                    focusNode: focusNode,
                    hint: 'Search By Plant',
                    onSubmitted: (value) {
                      _plantSearchController.text = value;
                      notifier.setSearchName(value);
                      notifier.loadGroupedPlants();
                    },
                  );
                },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 400,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(
                            option.plantName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: option.displayName != null
                              ? Text(option.displayName!)
                              : null,
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
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
        ),
      ],
    );
  }

  Widget _buildVirtualizedTable(PlantState state, PlantNotifier notifier) {
    if (state.groupedPlants.isEmpty && !state.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: const Text(
            'No record found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    if (state.isLoading && state.groupedPlants.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(48.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: state.groupedPlants.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Table header
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
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
                _tableHeaderCell('Actions', width: 100),
              ],
            ),
          );
        }

        final groupIndex = index - 1;
        final group = state.groupedPlants[groupIndex];
        final orgCode = group.plantOrganizationCode ?? 'unknown_$groupIndex';
        final isExpanded = state.expandedGroups.contains(orgCode);
        final isLast = groupIndex == state.groupedPlants.length - 1;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.grey.shade200),
              right: BorderSide(color: Colors.grey.shade200),
              bottom: isLast
                  ? BorderSide(color: Colors.grey.shade200)
                  : BorderSide.none,
            ),
            borderRadius: isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : BorderRadius.zero,
          ),
          child: _buildGroupSection(
            index: groupIndex,
            group: group,
            orgCode: orgCode,
            isExpanded: isExpanded,
            notifier: notifier,
            isLast: isLast,
          ),
        );
      },
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
        Container(
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
              const Expanded(flex: 2, child: SizedBox()), // Align with Company
              const Expanded(flex: 2, child: SizedBox()), // Align with State
              const Expanded(flex: 2, child: SizedBox()), // Align with Country
              const Expanded(flex: 2, child: SizedBox()), // Align with Status
              const Expanded(flex: 3, child: SizedBox()), // Align with Address
            ],
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
                        child: Text(
                          addr.fullAddress,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 18,
                              ),
                              onPressed: () => _showEditModal(group, addr),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red.shade400,
                                size: 18,
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
