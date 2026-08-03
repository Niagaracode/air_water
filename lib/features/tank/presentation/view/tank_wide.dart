import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_clear_button.dart';
import '../../../../shared/widgets/view_header.dart';
import '../../data/model/tank_model.dart';
import '../controller/tank_provider.dart';
import '../widgets/add_tank_modal.dart';
import '../../../site/presentation/model/site_model.dart';
import 'dart:async';

class TankWide extends ConsumerStatefulWidget {
  const TankWide({super.key});

  @override
  ConsumerState<TankWide> createState() => _TankWideState();
}

class _TankWideState extends ConsumerState<TankWide> {
  final _siteSearchController = TextEditingController();
  final _tankSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _siteSearchController.dispose();
    _tankSearchController.dispose();
    super.dispose();
  }

  /// HEADER-----------------------------------------
  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'TANK MANAGEMENT',
      subtitle:
      'Centralize tank information including dimensions, types, products and site associations.',
      buttonText: 'Add tank',
      onPressed: () => _showAddDialog(),
    );
  }

  Widget _buildFilterRow(TankState state, TankNotifier notifier) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildSiteAutocomplete(notifier)),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildTankAutocomplete(notifier)),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: AppDropdown<int?>(
            value: state.selectedStatus,
            items: const [null, 1, 0],
            itemLabel: (v) =>
            v == null ? 'All Status' : (v == 1 ? 'Active' : 'Inactive'),
            hint: 'Status',
            onChanged: (v) => notifier.setStatus(v),
          ),
        ),
        const SizedBox(width: 16),
        AppClearButton(
          onPressed: () {
            _siteSearchController.clear();
            _tankSearchController.clear();
            notifier.clearFilters();
          },
        ),
      ],
    );
  }

  Widget _buildSiteAutocomplete(TankNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<SiteAutocompleteInfo>(
          textEditingController: _siteSearchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<SiteAutocompleteInfo>.empty();
            }
            return await notifier.searchSites(textEditingValue.text);
          },
          displayStringForOption: (SiteAutocompleteInfo option) =>
          option.siteName,
          onSelected: (option) {
            notifier.setSearchSite(option.siteName);
            notifier.loadGroupedTanks();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Site',
              prefixIcon: const Icon(Icons.search, size: 20),
              onSubmitted: (v) {
                notifier.setSearchSite(v);
                notifier.loadGroupedTanks();
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
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option.siteName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          option.fullAddress,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTankAutocomplete(TankNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _tankSearchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await notifier.getTankNameSuggestions(textEditingValue.text);
          },
          displayStringForOption: (String option) => option,
          onSelected: (option) {
            notifier.setSearchTank(option);
            notifier.loadGroupedTanks();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return AppTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Filter By Tank',
              prefixIcon: const Icon(Icons.search, size: 20),
              onSubmitted: (v) {
                notifier.setSearchTank(v);
                notifier.loadGroupedTanks();
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
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tankNotifierProvider);
    final notifier = ref.read(tankNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.only(left: 30, bottom: 12, right: 24),
            child: _buildFilterRow(state, notifier),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth > 1000
                    ? constraints.maxWidth
                    : 1000.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            if (!state.isLoading ||
                                state.groupedTanks.isNotEmpty)
                              _buildFixedTableHeader(),
                            Expanded(
                              child: state.isLoading &&
                                  state.groupedTanks.isEmpty
                                  ? const AppTableInitialLoader()
                                  : _buildVirtualizedTable(state, notifier),
                            ),
                            if (state.isLoading &&
                                state.groupedTanks.isNotEmpty)
                              const AppTableLoadingMore(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(TankState state, TankNotifier notifier) {
    if (state.groupedTanks.isEmpty && !state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: AppTableEmptyState(
          icon: Icons.water_outlined,
          title: 'No tanks found',
        ),
      );
    }

    // Generate linear list (Site Headers + Tank Rows + Asset Groups)
    final List<dynamic> items = [];
    for (int i = 0; i < state.groupedTanks.length; i++) {
      final group = state.groupedTanks[i];
      items.add({'type': 'header', 'group': group, 'index': i + 1});
      for (final tank in group.tanks) {
        items.add({'type': 'row', 'tank': tank, 'group': group});
      }
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        if (item['type'] == 'header') {
          return _buildGroupHeader(
            item['group'] as TankGroup,
            item['index'] as int,
            isLast,
          );
        } else {
          return _buildTankRow(
            item['tank'] as Tank,
            notifier,
            isLast,
            item['group'] as TankGroup,
          );
        }
      },
    );
  }

  Widget _buildFixedTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          AppTableHeaderCell('Sl.no', width: 60),
          AppTableHeaderCell('Customer/tank id', width: 210),
          AppTableHeaderCell('Device id', width: 170),
          AppTableHeaderCell('Product', width: 120, textAlign: TextAlign.center),
          AppTableHeaderCell('Site information', flex: 3),
          AppTableHeaderCell(
            'Actions',
            width: 120,
            textAlign: TextAlign.right,
          ),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(TankGroup group, int index, bool isLast) {

    return Container(
      color: primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                index.toString().padLeft(2),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ),
            Text(
              group.siteName,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              group.fullAddress,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Spacer(),
            Text(
              '${group.tanks.length} ${group.tanks.length == 1 ? 'tank' : 'tanks'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Color(0xFF374151),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankRow(
      Tank tank,
      TankNotifier notifier,
      bool isLast,
      TankGroup group,
      ) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(
              color: primary.withValues(alpha: 0.6),
              width: 2,
            ),
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFF3F4F6)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 60),
              AppTableCell(tank.tankNumber ?? '--', width: 210),
              AppTableCell(tank.deviceId ?? '--', width: 170),
              AppTableCell(
                tank.productName ?? '--',
                width: 120,
                textAlign: TextAlign.center,
              ),
              AppTableCell(tank.fullAddress, flex: 3),
              SizedBox(
                width: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppTableActionButton(
                      icon: Icons.edit_outlined,
                      color: primary,
                      bg: primary.withValues(alpha: 0.1),
                      onTap: () => _showAddDialog(tank),
                    ),
                    const SizedBox(width: 16),
                    AppTableActionButton(
                      icon: Icons.delete_outline,
                      color: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEE2E2),
                      onTap: () => _showDeleteDialog(tank),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog([Tank? tank]) async {
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddTank',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AddTankModal(
        tank: tank,
        onSuccess: () {
          ref.read(tankNotifierProvider.notifier).loadGroupedTanks();
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Future<void> _showDeleteDialog(Tank tank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Tank',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete tank "${tank.tankNumber}"?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(tankNotifierProvider.notifier)
          .deleteTank(tank.tankId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tank deleted successfully',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }
}