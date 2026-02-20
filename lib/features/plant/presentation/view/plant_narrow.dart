import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/plant_provider.dart';
import '../widgets/add_plant_modal.dart';
import '../model/plant_model.dart';

class PlantNarrow extends ConsumerStatefulWidget {
  const PlantNarrow({super.key});

  @override
  ConsumerState<PlantNarrow> createState() => _PlantNarrowState();
}

class _PlantNarrowState extends ConsumerState<PlantNarrow> {
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildHeader(plantState, plantNotifier),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            sliver: _buildVirtualizedTable(plantState, plantNotifier),
          ),
          if (plantState.isLoading && plantState.groupedPlants.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
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

  Widget _buildHeader(PlantState plantState, PlantNotifier plantNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLANT MANAGEMENT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        RawAutocomplete<PlantAutocompleteInfo>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<PlantAutocompleteInfo>.empty();
            }
            return await plantNotifier.searchPlants(textEditingValue.text);
          },
          displayStringForOption: (PlantAutocompleteInfo option) =>
              option.plantName,
          onSelected: (PlantAutocompleteInfo selection) {
            _plantSearchController.text = selection.plantName;
            plantNotifier.setSearchName(selection.plantName);
            plantNotifier.loadGroupedPlants();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
                plantNotifier.setSearchName(value);
                plantNotifier.loadGroupedPlants();
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
                  width: MediaQuery.of(context).size.width - 24,
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.plantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: option.displayName != null
                            ? Text(
                                option.displayName!,
                                style: const TextStyle(fontSize: 11),
                              )
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
                        CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                      ),
                  child: child,
                );
              },
            );
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('ADD'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Showing  ${plantState.totalEntries} entries',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualizedTable(PlantState plantState, PlantNotifier notifier) {
    if (plantState.groupedPlants.isEmpty && !plantState.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: const Text(
            'No record found',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    if (plantState.isLoading && plantState.groupedPlants.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: plantState.groupedPlants.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Table header
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'SI.NO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'City',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }

        final groupIndex = index - 1;
        final group = plantState.groupedPlants[groupIndex];
        final orgCode = group.plantOrganizationCode ?? 'unknown_$groupIndex';
        final isExpanded = plantState.expandedGroups.contains(orgCode);
        final isLast = groupIndex == plantState.groupedPlants.length - 1;

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
          ),
        );
      },
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
