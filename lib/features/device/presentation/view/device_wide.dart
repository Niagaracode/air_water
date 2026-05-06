import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../../../../../shared/widgets/app_clear_button.dart';
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
      ref.read(deviceProvider.notifier).loadMore();
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

  Widget _buildHeader(DeviceState state, DeviceNotifier notifier) {
    return Container(
      padding: const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEVICE MANAGEMENT',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor and configure your water monitoring hardware across various sites.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddModal(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141E7A),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'ADD DEVICE',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'FILTER',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterRow(state, notifier),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(state.error!, notifier),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Showing ${state.groupedDevices.fold<int>(0, (sum, g) => sum + g.devices.length)} of ${state.totalEntries} entries',
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

  Widget _buildFilterRow(DeviceState state, DeviceNotifier notifier) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildSiteAutocomplete(notifier)),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildDeviceAutocomplete(notifier)),
        const SizedBox(width: 16),
        AppClearButton(
          onPressed: () {
            _siteSearchController.clear();
            _searchController.clear();
            notifier.clearFilters();
          },
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
    final state = ref.watch(deviceProvider);
    final notifier = ref.read(deviceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.1),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildHeader(state, notifier),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tableWidth = constraints.maxWidth > 1200 ? constraints.maxWidth : 1200.0;
                return Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          if (!state.isLoading || state.groupedDevices.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: _buildFixedTableHeader(),
                            ),
                          Expanded(
                            child: state.isLoading && state.groupedDevices.isEmpty
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF141E7A)))
                                : _buildVirtualizedTable(state, notifier),
                          ),
                          if (state.isLoading && state.groupedDevices.isNotEmpty)
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
          return _buildDeviceRow(
            item['device'] as Device,
            notifier,
            isLast,
          );
        }
      },
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
          AppTableHeaderCell('Date', flex: 2),
          AppTableHeaderCell('Device ID', flex: 3),
          AppTableHeaderCell('Company', flex: 2),
          AppTableHeaderCell('Sim Number', flex: 2),
          AppTableHeaderCell('Tank', flex: 2),
          AppTableHeaderCell('Status', flex: 2),
          AppTableHeaderCell('Action', width: 100),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(DeviceGroup group, int index, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border(
          left: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5),
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
              flex: 2, // Align with DATE column
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.siteName,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      '${group.devices.length} Devices',
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
            Expanded(
              flex: 13, // Align with the rest of columns (Total 15 - Date 2)
              child: group.devices.isNotEmpty && group.devices.first.siteInformation != null
                  ? Text(
                      group.devices.first.siteInformation!.fullAddress,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 100), // Match ACTION column width
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
          displayStringForOption: (SiteAutocompleteInfo option) => option.siteName,
          onSelected: (option) {
            notifier.setSearchSite(option.siteName);
            notifier.loadGroupedDevices();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Filter By Site Name',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF6B7280)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF141E7A), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (v) {
                notifier.setSearchSite(v);
                notifier.loadGroupedDevices();
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
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(option.fullAddress, style: GoogleFonts.inter(fontSize: 11)),
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
            return await notifier.getDeviceNameSuggestions(textEditingValue.text);
          },
          displayStringForOption: (String option) => option,
          onSelected: (option) {
            notifier.setSearchDevice(option);
            notifier.loadGroupedDevices();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Search By Device ID / Name',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6B7280)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF141E7A), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (v) {
                notifier.setSearchDevice(v);
                notifier.loadGroupedDevices();
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
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option, style: GoogleFonts.inter(fontSize: 13)),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device deleted successfully')));
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
