import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../../../../shared/widgets/view_header.dart';
import '../controller/device_provider.dart';
import '../model/device_model.dart';
import '../../../site/presentation/model/site_model.dart';
import '../widgets/add_device_modal.dart';

class DeviceWide extends ConsumerStatefulWidget {
  const DeviceWide({super.key});

  @override
  ConsumerState<DeviceWide> createState() => _DeviceWideState();
}

class _DeviceWideState extends ConsumerState<DeviceWide> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _siteSearchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(deviceNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _siteSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddModal([Device? device]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Device',
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddDeviceModal(device: device);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ViewHeader(
      title: 'DEVICE MANAGEMENT',
      subtitle:
          'Monitor and configure your water monitoring hardware across various sites.',
      buttonText: 'Add Device',
      onPressed: () => _showAddModal(),
    );
  }

  Widget _buildFilterRow(DeviceState state, DeviceNotifier notifier) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildSiteAutocomplete(notifier)),
        const SizedBox(width: 12),
        // Device search — dashboard style
        Expanded(flex: 2, child: _buildDeviceAutocomplete(notifier)),
        const SizedBox(width: 12),
        // Filter/Clear icon button — dashboard style
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141E7A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF141E7A)),
            tooltip: 'Clear all filters',
            onPressed: () {
              _siteSearchController.clear();
              _searchController.clear();
              notifier.clearFilters();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error, DeviceNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(
                color: const Color(0xFFDC2626),
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFDC2626), size: 16),
            onPressed: () => notifier.loadGroupedDevices(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceNotifierProvider);
    final notifier = ref.read(deviceNotifierProvider.notifier);

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
                final tableWidth = constraints.maxWidth > 1200
                    ? constraints.maxWidth
                    : 1200.0;
                return Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          if (!state.isLoading ||
                              state.groupedDevices.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: _buildFixedTableHeader(),
                            ),
                          Expanded(
                            child:
                                state.isLoading && state.groupedDevices.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF141E7A),
                                    ),
                                  )
                                : _buildVirtualizedTable(state, notifier),
                          ),
                          if (state.isLoading &&
                              state.groupedDevices.isNotEmpty)
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

  Widget _buildVirtualizedTable(DeviceState state, DeviceNotifier notifier) {
    if (state.groupedDevices.isEmpty && !state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: AppTableEmptyState(
          icon: Icons.devices_outlined,
          title: 'No devices found',
        ),
      );
    }

    // Generate linear list (Site Headers + Device Rows)
    final List<dynamic> items = [];
    for (int i = 0; i < state.groupedDevices.length; i++) {
      final group = state.groupedDevices[i];
      items.add({'type': 'header', 'group': group, 'index': i + 1});
      for (final device in group.devices) {
        items.add({'type': 'row', 'device': device, 'group': group});
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
            item['group'] as DeviceGroup,
            item['index'] as int,
            isLast,
          );
        } else {
          return _buildDeviceRow(item['device'] as Device, notifier, isLast);
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
          AppTableHeaderCell('SI.NO', width: 70),
          AppTableHeaderCell('Date', flex: 2),
          AppTableHeaderCell('Device ID', flex: 3),
          AppTableHeaderCell('Company', flex: 2),
          AppTableHeaderCell('Sim Number', flex: 2),
          AppTableHeaderCell('Tank', flex: 2),
          AppTableHeaderCell('Status', flex: 2),
          AppTableHeaderCell('Site Information', flex: 3),
          AppTableHeaderCell('Action', width: 100),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(DeviceGroup group, int index, bool isLast) {
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
              width: 70,
              child: Text(
                index.toString().padLeft(2),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                group.siteName ?? '',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Expanded(flex: 2, child: SizedBox()),
            const Expanded(flex: 2, child: SizedBox()),
            const Expanded(flex: 2, child: SizedBox()),
            const Expanded(flex: 2, child: SizedBox()),
            Expanded(
              flex: 3,
              child: Text(
                group.fullAddress,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceRow(Device device, DeviceNotifier notifier, bool isLast) {
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
            AppTableCell(device.createdAt?.split('T')[0] ?? '—', flex: 2),
            AppTableCell(device.deviceId, flex: 3, bold: true),
            AppTableCell(device.companyName ?? '—', flex: 2),
            AppTableCell(device.simNumber ?? '—', flex: 2),
            AppTableCell(device.tankName ?? '—', flex: 2),
            AppTableCell(
              null,
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppStatusBadge(status: device.status),
              ),
            ),
            const AppTableCell('', flex: 3),
            AppTableCell(
              null,
              width: 100,
              child: Row(
                children: [
                  AppTableActionButton(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                    onTap: () => _showAddModal(device),
                  ),
                  const SizedBox(width: 8),
                  AppTableActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFDC2626),
                    bg: const Color(0xFFFEF2F2),
                    onTap: () => _confirmDelete(device, notifier),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteAutocomplete(DeviceNotifier notifier) {
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
            notifier.loadGroupedDevices();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (v) {
                  notifier.setSearchSite(v);
                  if (v.isEmpty) notifier.loadGroupedDevices();
                },
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  hintText: 'Filter By Site Name',
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onSubmitted: (v) {
                  notifier.setSearchSite(v);
                  notifier.loadGroupedDevices();
                },
              ),
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
                  constraints: const BoxConstraints(maxHeight: 250),
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
                          style: GoogleFonts.inter(fontSize: 11),
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

  Widget _buildDeviceAutocomplete(DeviceNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          textEditingController: _searchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return await notifier.getDeviceNameSuggestions(
              textEditingValue.text,
            );
          },
          displayStringForOption: (String option) => option,
          onSelected: (option) {
            notifier.setSearchDevice(option);
            notifier.loadGroupedDevices();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (v) {
                  notifier.setSearchDevice(v);
                  if (v.isEmpty) notifier.loadGroupedDevices();
                },
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  hintText: 'Search devices...',
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                onSubmitted: (v) {
                  notifier.setSearchDevice(v);
                  notifier.loadGroupedDevices();
                },
              ),
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
                  constraints: const BoxConstraints(maxHeight: 250),
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

  Future<void> _confirmDelete(Device device, DeviceNotifier notifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await notifier.deleteDevice(device.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device deleted successfully')),
        );
      }
    }
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, this.height = 56});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
