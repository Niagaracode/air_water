import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:air_water/shared/widgets/app_text_field.dart';
import '../../../../core/app_theme/app_theme.dart';
import 'package:air_water/shared/widgets/app_dropdown.dart';
import 'package:air_water/shared/widgets/app_date_picker.dart';
import '../controller/site_provider.dart';
import '../widgets/add_site_modal.dart';
import '../model/site_model.dart';
import '../../../../shared/widgets/app_clear_button.dart';

class SiteMiddle extends ConsumerStatefulWidget {
  const SiteMiddle({super.key});

  @override
  ConsumerState<SiteMiddle> createState() => _SiteMiddleState();
}

class _SiteMiddleState extends ConsumerState<SiteMiddle> {
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
                    'Dashboard >> Site',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildHeader(siteState, siteNotifier),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: _buildVirtualizedTable(siteState, siteNotifier),
          ),
          if (siteState.isLoading && siteState.groupedSites.isNotEmpty)
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
                    const Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey,
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

  Widget _buildHeader(SiteState state, SiteNotifier notifier) {
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
            'SITE MANAGEMENT',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Centralize Site Information Including Identification, Locations, And Status Management',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildFilters(notifier, state),
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

  Widget _buildVirtualizedTable(SiteState state, SiteNotifier notifier) {
    if (state.groupedSites.isEmpty && !state.isLoading) {
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
            'No sites found',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    if (state.isLoading && state.groupedSites.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
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

    return SliverList.builder(
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
    String headerText;
    int addressesCount = 0;
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
        headerText = foundSiteName ?? '';
      }
      addressesCount = group.addresses.length;
    } catch (e) {
      headerText = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          top: index == 1
              ? BorderSide(color: Colors.grey.shade200)
              : BorderSide.none,
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
        borderRadius: index == 1
            ? const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              )
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    headerText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                    overflow: TextOverflow.ellipsis,
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
                    '$addressesCount SITES',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteRow(
    SiteGroupAddress site,
    SiteGroup group,
    bool isLast,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade200),
          right: BorderSide(color: Colors.grey.shade200),
          bottom: isLast
              ? BorderSide(color: Colors.grey.shade200)
              : BorderSide(color: Colors.grey.shade100),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              flex: 2,
              child: Text(
                site.city ?? '—',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                site.createdAt != null
                    ? (site.createdAt!.contains('T')
                          ? site.createdAt!.split('T').first
                          : site.createdAt!)
                    : '—',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                site.companyName ?? '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                site.state ?? '—',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    site.country ?? '—',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (site.timeZone != null)
                    Text(
                      site.timeZone!,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: site.status == 1 ? Colors.green : Colors.grey,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    site.status == 1 ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: site.status == 1 ? Colors.green : Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                site.fullAddress,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: primary,
                      size: 16,
                    ),
                    onPressed: () => _showEditModal(site.toSite()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 16,
                    ),
                    onPressed: () => _showDeleteDialog(site.toSite()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditModal(Site site) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, anim1, anim2) =>
          AddSiteModal(initialSite: site),
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

  Future<void> _showDeleteDialog(Site site) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${site.name}"?'),
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

  Widget _buildFilters(SiteNotifier notifier, SiteState state) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 250,
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
                            option.siteName,
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
        AppClearButton(
          onPressed: () {
            _siteSearchController.clear();
            notifier.clearFilters();
          },
        ),
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
            );
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('ADD'),
        ),
      ],
    );
  }
}
