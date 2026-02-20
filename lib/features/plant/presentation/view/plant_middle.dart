import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/plant_provider.dart';
import '../widgets/add_plant_modal.dart';
import '../model/plant_model.dart';

class PlantMiddle extends ConsumerStatefulWidget {
  const PlantMiddle({super.key});

  @override
  ConsumerState<PlantMiddle> createState() => _PlantMiddleState();
}

class _PlantMiddleState extends ConsumerState<PlantMiddle> {
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard >> Plant',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildHeader(plantState, plantNotifier),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
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
          const SizedBox(height: 8),
          const Text(
            'Centralize Plant Information Including Identification, Locations, And Status Management',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildFilters(notifier),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing  ${state.totalEntries} entries',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(PlantState state, PlantNotifier notifier) {
    if (state.groupedPlants.isEmpty && !state.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32),
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

    if (state.isLoading && state.groupedPlants.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32.0),
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
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
            child: const Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'SI.NO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'City',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Company',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'State',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Country',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Address',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
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
          ),
        );
      },
    );
  }

  Widget _buildFilters(PlantNotifier notifier) {
    final state = ref.watch(plantNotifierProvider);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 250, // Slightly wider for middle
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
                    width: 300,
                    constraints: const BoxConstraints(maxHeight: 250),
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
        ),
        SizedBox(
          width: 150,
          child: AppDropdown<int>(
            value: state.selectedStatus,
            items: const [1, 0],
            hint: 'Status',
            itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
            onChanged: (v) => notifier.setStatus(v),
          ),
        ),
        SizedBox(
          width: 180,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              SizedBox(
                width: 50,
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
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 50),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.city ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.createdAt?.split('T').first ?? '',
                          style: const TextStyle(fontSize: 12),
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
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              addr.companyFullAddress,
                              style: TextStyle(
                                fontSize: 10,
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
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          addr.country ?? '',
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
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.fullAddress,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              addr.plantLocation,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
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
  }
}
