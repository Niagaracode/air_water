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
import 'package:go_router/go_router.dart';
import 'dart:async';

class TankWide extends ConsumerStatefulWidget {
  const TankWide({super.key});

  @override
  ConsumerState<TankWide> createState() => _TankWideState();
}

class _TankWideState extends ConsumerState<TankWide> {
  final _siteSearchController = TextEditingController();
  final _tankSearchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(tankNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _siteSearchController.dispose();
    _tankSearchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
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
            itemLabel: (v) => v == null ? 'All Status' : (v == 1 ? 'Active' : 'Inactive'),
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
          displayStringForOption: (SiteAutocompleteInfo option) => option.siteName,
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
                final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000.0;
                return Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          if (!state.isLoading || state.groupedTanks.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: _buildFixedTableHeader(),
                            ),
                          Expanded(
                            child: state.isLoading && state.groupedTanks.isEmpty
                                ? const AppTableInitialLoader()
                                : _buildVirtualizedTable(state, notifier),
                          ),
                          if (state.isLoading && state.groupedTanks.isNotEmpty)
                            const AppTableLoadingMore(),
                        ],
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
        padding: EdgeInsets.symmetric(horizontal: 24),
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
        }else {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 60),
          AppTableHeaderCell('Site/ Tank', flex: 2),
          AppTableHeaderCell('Device id', flex: 2),
          AppTableHeaderCell('Site Information', flex: 3),
          AppTableHeaderCell('Product', flex: 1, textAlign: TextAlign.center),
          AppTableHeaderCell('Status', flex: 1),
          AppTableHeaderCell('Actions', width: 80),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(TankGroup group, int index, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          right: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              group.siteName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.tanks.length} tanks',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankRow(Tank tank, TankNotifier notifier, bool isLast, TankGroup group) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          right: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: isLast
              ? BorderSide(color: Colors.grey.shade300, width: 1)
              : const BorderSide(color: Color(0xFFF3F4F6)),
        ),
        borderRadius: isLast ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            const SizedBox(width: 60),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => context.go('/tank/details/${tank.tankId}', extra: tank),
                child: Text(
                  tank.tankNumber,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            AppTableCell(tank.deviceId ?? '--', flex: 2),

            AppTableCell(group.fullAddress, flex: 3),

            AppTableCell(tank.productName ?? '--', flex: 1, textAlign: TextAlign.center,),

            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppStatusBadge(status: tank.status),
              ),
            ),
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  AppTableActionButton(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                    onTap: () => _showAddDialog(tank),
                  ),
                  const SizedBox(width: 5),
                  AppTableActionButton(
                    icon: Icons.delete_outline,
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEE2E2),
                    onTap: () => _showDeleteDialog(tank),
                  ),
                ],
              ),
            ),
          ],
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
          ).animate(
            CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOut,
            ),
          ),
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