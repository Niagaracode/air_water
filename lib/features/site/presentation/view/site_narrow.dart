import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/site_provider.dart';
import '../widgets/add_site_modal.dart';
import '../model/site_model.dart';
import '../../../../shared/widgets/app_clear_button.dart';

class SiteNarrow extends ConsumerStatefulWidget {
  const SiteNarrow({super.key});

  @override
  ConsumerState<SiteNarrow> createState() => _SiteNarrowState();
}

class _SiteNarrowState extends ConsumerState<SiteNarrow> {
  final _siteSearchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchFocusNode = FocusNode();

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
    _searchFocusNode.dispose();
    super.dispose();
  }

  static final List<Color> _groupColors = [
    const Color(0xFF6366F1), // indigo
    const Color(0xFF0EA5E9), // sky
    const Color(0xFF10B981), // emerald
    const Color(0xFFF59E0B), // amber
    const Color(0xFFEC4899), // pink
    const Color(0xFF8B5CF6), // violet
    const Color(0xFF14B8A6), // teal
  ];

  Color _colorForGroup(String key) {
    if (key.trim().isEmpty) return primary;
    final hash =
    key.toLowerCase().trim().codeUnits.fold<int>(0, (p, c) => p + c);
    return _groupColors[hash % _groupColors.length];
  }

  void _clearSearch() {
    _siteSearchController.clear();
    _searchFocusNode.unfocus();
    ref.read(siteNotifierProvider.notifier).setSearchName('');
    ref.read(siteNotifierProvider.notifier).loadGroupedSites(isReload: true);
  }

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteNotifierProvider);
    final siteNotifier = ref.read(siteNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        elevation: 2,
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
                ).animate(
                  CurvedAnimation(parent: anim1, curve: Curves.easeOut),
                ),
                child: child,
              );
            },
          );
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add site',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _buildHeader(siteState, siteNotifier),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            sliver: _buildVirtualizedList(siteState, siteNotifier),
          ),
          if (siteState.isLoading && siteState.groupedSites.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Loading more sites…',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  Widget _buildHeader(SiteState siteState, SiteNotifier siteNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_on_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Showing ${siteState.totalEntries} entries',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search bar with built-in clear button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7E9F0)),
          ),
          child: RawAutocomplete<SiteAutocompleteInfo>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<SiteAutocompleteInfo>.empty();
              }
              return await siteNotifier.searchSites(textEditingValue.text);
            },
            displayStringForOption: (SiteAutocompleteInfo option) =>
            option.siteName,
            onSelected: (SiteAutocompleteInfo selection) {
              _siteSearchController.text = selection.siteName;
              siteNotifier.setSearchName(selection.siteName);
              siteNotifier.loadGroupedSites(isReload: true);
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              if (_siteSearchController.text != controller.text &&
                  _siteSearchController.text.isNotEmpty &&
                  controller.text.isEmpty) {
                controller.text = _siteSearchController.text;
              }

              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Search by site name',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          _siteSearchController.clear();
                          siteNotifier.clearFilters();
                          _searchFocusNode.unfocus();
                          siteNotifier.setSearchName('');
                          siteNotifier.loadGroupedSites(isReload: true);
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                          : const SizedBox.shrink();
                    },
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
                onFieldSubmitted: (value) {
                  _siteSearchController.text = value;
                  siteNotifier.setSearchName(value);
                  siteNotifier.loadGroupedSites(isReload: true);
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 32,
                    constraints: const BoxConstraints(maxHeight: 220),
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
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: option.displayName != null
                              ? Text(
                            option.displayName!,
                            style: GoogleFonts.inter(fontSize: 12.5),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDropdown<int>(
                value: siteState.selectedStatus,
                items: const [1, 0],
                hint: 'Status',
                itemLabel: (v) => v == 1 ? 'Active' : 'Inactive',
                onChanged: (v) => siteNotifier.setStatus(v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppDatePickerField(
                selectedDate: siteState.selectedDate != null
                    ? DateTime.parse(siteState.selectedDate!)
                    : null,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (date) {
                  if (date != null) {
                    final formatted =
                        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    siteNotifier.setDate(formatted);
                  } else {
                    siteNotifier.setDate(null);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVirtualizedList(SiteState siteState, SiteNotifier notifier) {
    if (siteState.groupedSites.isEmpty && !siteState.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.location_off_rounded,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No sites found',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (siteState.isLoading && siteState.groupedSites.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SliverList.builder(
      itemCount: siteState.groupedSites.length,
      itemBuilder: (context, index) {
        final group = siteState.groupedSites[index];
        return _buildGroupCard(group, index + 1);
      },
    );
  }

  Widget _buildGroupCard(SiteGroup group, int index) {
    String headerText;
    try {
      final raw = (group.name ?? '').trim();
      if (raw.isNotEmpty && raw != 'null') {
        headerText = raw;
      } else {
        String? foundSiteName;
        for (final addr in group.addresses) {
          final sn = (addr.siteName ?? '').trim();
          if (sn.isNotEmpty && sn != 'null') {
            foundSiteName = sn;
            break;
          }
        }
        headerText = foundSiteName ?? 'Untitled group';
      }
    } catch (e) {
      headerText = 'Untitled group';
    }

    final groupColor = _colorForGroup(headerText);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: groupColor.withValues(alpha: 0.08),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: groupColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: groupColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    headerText,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: groupColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${group.addresses.length} sites',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: groupColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Site rows
          ...List.generate(group.addresses.length, (i) {
            final isLast = i == group.addresses.length - 1;
            return _buildSiteRow(group.addresses[i], isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildSiteRow(SiteGroupAddress site, bool isLast) {
    return InkWell(
      onTap: () => _showEditModal(site.toSite()),
      borderRadius: BorderRadius.only(
        bottomLeft: isLast ? Radius.circular(16) : Radius.zero,
        bottomRight: isLast ? Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade100),
          ),
          borderRadius: isLast
              ? const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
              : BorderRadius.zero,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.siteName ?? '—',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.apartment_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${site.companyName ?? '—'} · ${site.city ?? '—'}, ${site.country ?? '—'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (site.timeZone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text(
                          site.timeZone!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          site.fullAddress,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Delete button only
            InkWell(
              onTap: () => _showDeleteDialog(site.toSite()),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSiteBottomSheet([Site? site]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: AddSiteModal(initialSite: site),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditModal(Site site) {
    _showSiteBottomSheet(site);
  }

  Future<void> _showDeleteDialog(Site site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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