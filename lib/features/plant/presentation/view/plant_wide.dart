import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import 'package:air_water/shared/widgets/app_table.dart';
import '../controller/plant_provider.dart';
import '../widgets/add_plant_modal.dart';
import '../model/plant_model.dart';
import 'package:air_water/shared/widgets/app_clear_button.dart';

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
            const SliverToBoxAdapter(child: AppTableLoadingMore()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(PlantState state, PlantNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLANT MANAGEMENT',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Centralize plant information including identification, locations, and status management.',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          // Filter label
          Text(
            'FILTER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildFilterRow(notifier),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.totalEntries} entries',
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: option.displayName != null
                              ? Text(
                                  option.displayName!,
                                  style: GoogleFonts.inter(fontSize: 12),
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
        const SizedBox(width: 16),
        AppClearButton(
          onPressed: () {
            _plantSearchController.clear();
            notifier.clearFilters();
          },
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
          label: Text(
            'ADD PLANT',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualizedTable(PlantState state, PlantNotifier notifier) {
    if (state.groupedPlants.isEmpty && !state.isLoading) {
      return const SliverToBoxAdapter(
        child: AppTableEmptyState(
          icon: Icons.park_outlined,
          title: 'No plants found',
        ),
      );
    }

    if (state.isLoading && state.groupedPlants.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(48.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF141E7A)),
              const SizedBox(height: 16),
              Text(
                'Loading records...',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontSize: 14,
                ),
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
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A),
              border: Border(
                top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                AppTableHeaderCell('SI.NO', width: 70),
                AppTableHeaderCell('City', flex: 2),
                AppTableHeaderCell('Date', flex: 2),
                AppTableHeaderCell('Company', flex: 2),
                AppTableHeaderCell('State', flex: 2),
                AppTableHeaderCell('Country', flex: 2),
                AppTableHeaderCell('Status', flex: 2),
                AppTableHeaderCell('Address', flex: 3),
                AppTableHeaderCell('Actions', width: 100),
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
              left: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              right: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              bottom: isLast
                  ? const BorderSide(color: Color(0xFFD1D5DB), width: 1.5)
                  : BorderSide.none,
            ),
            borderRadius: isLast
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
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
        if (index > 0)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
        // Group header row - light blue
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            border: Border(
              left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
              bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  group.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(flex: 3, child: SizedBox()),
            ],
          ),
        ),
        // Address rows
        if (isExpanded)
          ...group.addresses.map((addr) {
            return Column(
              children: [
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3F4F6),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 70),
                      AppTableCell(addr.city ?? '—', flex: 2),
                      AppTableCell(
                        addr.createdAt?.split('T').first ?? '—',
                        flex: 2,
                      ),
                      AppTableCell(
                        null,
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.companyName ?? '—',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            Text(
                              addr.companyFullAddress,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppTableCell(addr.state ?? '—', flex: 2),
                      AppTableCell(addr.country ?? '—', flex: 2),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppStatusBadge(status: addr.status),
                        ),
                      ),
                      AppTableCell(addr.fullAddress, flex: 3),
                      SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            AppTableActionButton(
                              icon: Icons.edit_outlined,
                              color: const Color(0xFF2563EB),
                              bg: const Color(0xFFEFF6FF),
                              onTap: () => _showEditModal(group, addr),
                            ),
                            const SizedBox(width: 8),
                            AppTableActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: const Color(0xFFDC2626),
                              bg: const Color(0xFFFEF2F2),
                              onTap: () => _showDeleteDialog(addr),
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
