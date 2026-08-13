import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import 'package:air_water/shared/widgets/app_table.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../layout/provider/search_provider.dart';
import '../../../../shared/widgets/view_header.dart';
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

    // Search text now comes from the global header search bar.
    /*final searchText = ref.watch(globalSearchProvider);
    ref.listen<String>(globalSearchProvider, (previous, next) {
      widget.onSearchChanged(next);
    });*/

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
         /* Padding(
            padding: const EdgeInsets.only(left: 30, bottom: 12, right: 24),
            child: _buildFilterRow(siteNotifier, siteState),
          ),*/
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          if (!siteState.isLoading ||
                              siteState.groupedSites.isNotEmpty)
                            _buildFixedTableHeader(),
                          Expanded(
                            child:
                            siteState.isLoading &&
                                siteState.groupedSites.isEmpty
                                ? const AppTableInitialLoader()
                                : _buildVirtualizedTable(
                              siteState,
                              siteNotifier,
                            ),
                          ),
                          if (siteState.isLoading &&
                              siteState.groupedSites.isNotEmpty)
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

  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'SITE MANAGEMENT',
      subtitle:
      'Centralize site information including identification, locations, and status management.',
      buttonText: 'Add Site',
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
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
              child: child,
            );
          },
        ).then((_) {
          ref
              .read(siteNotifierProvider.notifier)
              .loadGroupedSites(isReload: true);
        });
      },
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
        AppClearButton(
          onPressed: () {
            _siteSearchController.clear();
            notifier.clearFilters();
          },
        ),
      ],
    );
  }

  Widget _buildVirtualizedTable(SiteState state, SiteNotifier notifier) {
    if (state.groupedSites.isEmpty && !state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: AppTableEmptyState(
          icon: Icons.park_outlined,
          title: 'No sites found',
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.groupedSites.length,
      itemBuilder: (context, index) {
        final group = state.groupedSites[index];
        return _buildSiteGroup(group, index + 1);
      },
    );
  }

  Widget _buildSiteGroup(SiteGroup group, int index) {
    final siteName = () {
      final raw = (group.name ?? '').trim();
      if (raw.isNotEmpty && raw != 'null') return raw;
      String? foundSiteName;
      for (final addr in group.addresses) {
        final sn = (addr.siteName ?? '').trim();
        if (sn.isNotEmpty && sn != 'null') {
          foundSiteName = sn;
          break;
        }
      }
      return foundSiteName ?? '';
    }();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Timeline column: numbered circle + connecting line ----
          SizedBox(
            width: 60,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$index',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Line only draws if there are rows beneath to connect to.
                if (group.addresses.isNotEmpty)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: primary.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          // ---- Content column: header + rows ----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGroupHeader(group, siteName),
                ...group.addresses.asMap().entries.map(
                      (entry) => _buildSiteRow(
                    entry.value,
                    group,
                    entry.key == group.addresses.length - 1,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildGroupHeader(SiteGroup group, String siteName) {
    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            siteName,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${group.addresses.length} ${group.addresses.length == 1 ? 'location' : 'locations'}',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF374151)),
        ],
      ),
    );
  }

  Widget _buildFixedTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 60), // aligns with the 60px timeline column
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AppTableHeaderCell('City', flex: 2),
            AppTableHeaderCell('State', width: 200),
            AppTableHeaderCell('Country', width: 200),
            AppTableHeaderCell('Address', flex: 3),
            AppTableHeaderCell('Action', width: 120, textAlign: TextAlign.right),
            SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteRow(SiteGroupAddress site, SiteGroup group, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            AppTableCell(site.city ?? '--', flex: 2),
            AppTableCell(site.state ?? '--', width: 200),
            AppTableCell(site.country ?? '--', width: 200),
            AppTableCell(site.fullAddress, flex: 3),
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTableActionButton(
                    icon: Icons.edit_outlined,
                    color: primary,
                    bg: primary.withValues(alpha: 0.1),
                    onTap: () => _showEditModal(site.toSite(), targetAddressId: site.id),
                  ),
                  const SizedBox(width: 16),
                  AppTableActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEF2F2),
                    onTap: () => _showDeleteDialog(site.toSite()),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
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