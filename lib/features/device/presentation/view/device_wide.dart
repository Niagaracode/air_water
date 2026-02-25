import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../../../../../shared/widgets/app_clear_button.dart';
import '../controller/device_provider.dart';
import '../model/device_model.dart';
import '../../../plant/presentation/model/plant_model.dart';
import '../widgets/add_device_modal.dart';

class DeviceWide extends ConsumerStatefulWidget {
  const DeviceWide({super.key});

  @override
  ConsumerState<DeviceWide> createState() => _DeviceWideState();
}

class _DeviceWideState extends ConsumerState<DeviceWide> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _plantSearchController = TextEditingController();
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
    _plantSearchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceProvider);
    final notifier = ref.read(deviceProvider.notifier);

    if (state.searchPlant != _plantSearchController.text &&
        state.searchPlant.isEmpty) {
      _plantSearchController.text = '';
    }
    if (state.searchDevice != _searchController.text &&
        state.searchDevice.isEmpty) {
      _searchController.text = '';
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildHeader(state, notifier),
          ),
          if (!state.isLoading || state.groupedDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildFixedTableHeader(),
            ),
          Expanded(
            child: state.isLoading && state.groupedDevices.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF141E7A)),
                  )
                : state.error != null
                ? Center(child: Text(state.error!))
                : _buildVirtualizedTable(state, notifier),
          ),
          if (state.isLoading && state.groupedDevices.isNotEmpty)
            const AppTableLoadingMore(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(DeviceState state, DeviceNotifier notifier) {
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
                    'Centralize device information including identification, configuration, connectivity, and status management.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddModal(),
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
          const SizedBox(height: 20),
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
          Row(
            children: [
              Expanded(child: _buildDeviceAutocomplete(notifier)),
              const SizedBox(width: 16),
              Expanded(child: _buildPlantAutocomplete(notifier)),
              const SizedBox(width: 16),
              AppClearButton(
                onPressed: () {
                  _searchController.clear();
                  _plantSearchController.clear();
                  notifier.clearFilters();
                },
              ),
            ],
          ),
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
      child: Row(
        children: [
          const AppTableHeaderCell('SI.NO', width: 70),
          const AppTableHeaderCell('Date', flex: 2),
          const AppTableHeaderCell('Device ID', flex: 2),
          const AppTableHeaderCell('Company', flex: 2),
          const AppTableHeaderCell('Category', flex: 2),
          const AppTableHeaderCell('Sim Number', flex: 2),
          const AppTableHeaderCell('Notes', flex: 3),
          const AppTableHeaderCell('Tank', flex: 2),
          const AppTableHeaderCell('Time Zone', flex: 2),
          const AppTableHeaderCell('Status', flex: 2),
          const AppTableHeaderCell('Action', width: 100),
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

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: state.groupedDevices.length,
            itemBuilder: (context, index) {
              final group = state.groupedDevices[index];

              return Column(
                children: [
                  // Plant Group Header - light blue
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      border: Border(
                        left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                        right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                        bottom: BorderSide(
                          color: Color(0xFFD1D5DB),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            (index + 1).toString().padLeft(2, '0'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    group.siteName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E40AF),
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
                                      border: Border.all(
                                        color: const Color(0xFFBFDBFE),
                                      ),
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
                              if (group.devices.isNotEmpty &&
                                  group.devices.first.siteInformation != null)
                                Text(
                                  group
                                      .devices
                                      .first
                                      .siteInformation!
                                      .fullAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Device Rows
                  ...group.devices.map(
                    (device) => _buildDeviceRow(device, notifier),
                  ),
                ],
              );
            },
          ),
        ),
        if (state.groupedDevices.isNotEmpty)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(child: AppTableBottomCap()),
          ),
      ],
    );
  }

  Widget _buildDeviceRow(Device device, DeviceNotifier notifier) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          right: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const AppTableCell(null, width: 70), // SI.NO placeholder space
          AppTableCell(device.createdAt?.split('T')[0] ?? '—', flex: 2),
          AppTableCell(device.deviceId, flex: 2, bold: true),
          AppTableCell(device.companyName ?? '—', flex: 2),
          AppTableCell(device.category ?? '—', flex: 2),
          AppTableCell(device.simNumber ?? '—', flex: 2),
          AppTableCell(device.notes ?? '—', flex: 3),
          AppTableCell(device.tankName ?? '—', flex: 2),
          AppTableCell(device.timeZone ?? '—', flex: 2),
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
    );
  }

  Widget _buildPlantAutocomplete(DeviceNotifier notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<PlantAutocompleteInfo>(
          textEditingController: _plantSearchController,
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<PlantAutocompleteInfo>.empty();
            }
            return await notifier.searchPlants(textEditingValue.text);
          },
          displayStringForOption: (PlantAutocompleteInfo option) =>
              option.plantName,
          onSelected: (option) {
            notifier.setSearchPlant(option.plantName);
            notifier.loadGroupedDevices();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Filter By Plant Name',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF141E7A),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (v) {
                notifier.setSearchPlant(v);
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
                          option.plantName,
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
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Search By Device ID / Name',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF141E7A),
                    width: 2,
                  ),
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
