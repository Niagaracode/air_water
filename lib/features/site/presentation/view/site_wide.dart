import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import 'package:air_water/shared/widgets/app_table.dart';
import '../controller/site_provider.dart';
import '../widgets/add_site_modal.dart';
import '../model/site_model.dart';
import 'package:air_water/shared/widgets/app_clear_button.dart';

class SiteWide extends ConsumerStatefulWidget {
  const SiteWide({super.key});

  @override
  ConsumerState<SiteWide> createState() => _SiteWideState();
}

class _SiteWideState extends ConsumerState<SiteWide> {
  final _siteSearchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(siteNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _siteSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteNotifierProvider);
    final siteNotifier = ref.read(siteNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildHeader(siteState, siteNotifier),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth > 1200
                    ? constraints.maxWidth
                    : 1200.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        if (!siteState.isLoading ||
                            siteState.groupedSites.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: _buildFixedTableHeader(),
                          ),
                        Expanded(
                          child:
                              siteState.isLoading &&
                                  siteState.groupedSites.isEmpty
                              ? const AppTableInitialLoader()
                              : _buildVirtualizedTable(siteState, siteNotifier),
                        ),
                        if (siteState.isLoading &&
                            siteState.groupedSites.isNotEmpty)
                          const AppTableLoadingMore(),
                      ],
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

  Widget _buildHeader(SiteState state, SiteNotifier notifier) {
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
            'SITE MANAGEMENT',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Centralize site information including identification, locations, and status management.',
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
          _buildFilterRow(notifier, state),
          const SizedBox(height: 10),
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: Text(
          //     'Showing ${state.totalEntries} entries',
          //     style: GoogleFonts.inter(
          //       color: const Color(0xFF9CA3AF),
          //       fontSize: 12,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(SiteNotifier notifier, SiteState state) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: RawAutocomplete<SiteAutocompleteInfo>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<SiteAutocompleteInfo>.empty();
              }
              return await notifier.searchSites(textEditingValue.text);
            },
            displayStringForOption: (SiteAutocompleteInfo option) =>
                option.siteName,
            onSelected: (SiteAutocompleteInfo selection) {
              _siteSearchController.text = selection.siteName;
              notifier.setSearchName(selection.siteName);
              notifier.loadGroupedSites(isReload: true);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  if (_siteSearchController.text != controller.text &&
                      _siteSearchController.text.isNotEmpty &&
                      controller.text.isEmpty) {
                    controller.text = _siteSearchController.text;
                  }

                  return AppTextField(
                    controller: controller,
                    focusNode: focusNode,
                    hint: 'Search By Site',
                    onSubmitted: (value) {
                      _siteSearchController.text = value;
                      notifier.setSearchName(value);
                      notifier.loadGroupedSites(isReload: true);
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
                            option.siteName,
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
            _siteSearchController.clear();
            notifier.clearFilters();
          },
        ),
        const SizedBox(width: 32),
        ElevatedButton.icon(
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: 'AddSite',
              barrierColor: Colors.black54,
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, anim1, anim2) => const AddSiteModal(),
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
            ).then((_) {
              ref
                  .read(siteNotifierProvider.notifier)
                  .loadGroupedSites(isReload: true);
            });
          },
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'ADD SITE',
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

  Widget _buildFixedTableHeader() {
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
      child: const Row(
        children: [
          AppTableHeaderCell('SI.NO', width: 70),
          AppTableHeaderCell('City', flex: 2),

          AppTableHeaderCell('Company', flex: 2),
          AppTableHeaderCell('State', flex: 2),
          AppTableHeaderCell('Country', flex: 2),
          AppTableHeaderCell('Status', flex: 2),
          AppTableHeaderCell('Address', flex: 3),
          AppTableHeaderCell('Action', width: 100),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(SiteState state, SiteNotifier notifier) {
    if (state.groupedSites.isEmpty && !state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: AppTableEmptyState(
          icon: Icons.park_outlined,
          title: 'No sites found',
        ),
      );
    }

    // Generate linear list of items (headers and rows)
    final List<dynamic> items = [];
    for (int i = 0; i < state.groupedSites.length; i++) {
      final group = state.groupedSites[i];
      items.add({'type': 'header', 'group': group, 'index': i + 1});

      for (final addr in group.addresses) {
        items.add({'type': 'row', 'address': addr, 'group': group});
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
            state,
            item['group'] as SiteGroup,
            item['index'] as int,
            isLast,
          );
        } else {
          return _buildSiteRow(
            item['address'] as SiteGroupAddress,
            item['group'] as SiteGroup,
            isLast,
          );
        }
      },
    );
  }

  Widget _buildGroupHeader(
    SiteState state,
    SiteGroup group,
    int index,
    bool isLast,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // More visible blue 50
        border: Border(
          left: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E40AF),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E40AF),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${group.addresses.length} Sites',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteRow(SiteGroupAddress site, SiteGroup group, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: isLast
              ? const BorderSide(color: Color(0xFFD1D5DB), width: 1.5)
              : const BorderSide(color: Color(0xFFF3F4F6)),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              )
            : BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            const AppTableCell(null, width: 70),
            AppTableCell(site.city ?? '--', flex: 2),

            AppTableCell(
              site.companyName ?? '--',
              flex: 2,
              bold: true,
              fontSize: 13,
              color: const Color(0xFF111827),
            ),
            const SizedBox(width: 16),
            AppTableCell(site.state ?? '--', flex: 2),
            AppTableCell(site.country ?? '--', flex: 2),
            AppTableCell(
              null,
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppStatusBadge(status: site.status ?? 1),
              ),
            ),

            AppTableCell(site.fullAddress, flex: 3),
            AppTableCell(
              null,
              width: 100,
              child: Row(
                children: [
                  AppTableActionButton(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                    onTap: () =>
                        _showEditModal(site.toSite(), targetAddressId: site.id),
                  ),

                  const SizedBox(width: 8),
                  AppTableActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEF2F2),
                    onTap: () => _showDeleteDialog(site.toSite()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal(Site site, {int? targetAddressId}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) {
        return AddSiteModal(
          initialSite: site,
          targetAddressId: targetAddressId,
        );
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
    ).then((_) {
      ref.read(siteNotifierProvider.notifier).loadGroupedSites(isReload: true);
    });
  }

  Future<void> _showDeleteDialog(Site site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text(
          'Are you sure you want to delete "${site.name}" at "${site.cityName}"?',
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

    if (confirmed == true) {
      final success = await ref
          .read(siteNotifierProvider.notifier)
          .deleteSite(site.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site deleted successfully')),
        );
      }
    }
  }
}
