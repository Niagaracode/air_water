import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/device_provider.dart';
import '../model/device_model.dart';
import '../widgets/add_device_modal.dart';

class DeviceNarrow extends ConsumerStatefulWidget {
  const DeviceNarrow({super.key});

  @override
  ConsumerState<DeviceNarrow> createState() => _DeviceNarrowState();
}

class _DeviceNarrowState extends ConsumerState<DeviceNarrow> {
  final TextEditingController _searchController = TextEditingController();
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

    // Sync controllers
    if (state.searchDevice != _searchController.text &&
        state.searchDevice.isEmpty) {
      _searchController.text = '';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildHeader(notifier),
                  const SizedBox(height: 12),
                  if (state.error != null) _buildErrorBanner(state.error!),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: _buildVirtualizedList(state, notifier),
          ),
          if (state.isLoading && state.groupedDevices.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
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

  Widget _buildHeader(DeviceNotifier notifier) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DEVICE MANAGEMENT',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () => _showAddModal(),
              child: const Text('ADD'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search By Device ID',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  notifier.setSearchDevice(value);
                  notifier.loadGroupedDevices();
                },
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                notifier.clearFilters();
              },
              child: const Text('CLEAR'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVirtualizedList(DeviceState state, DeviceNotifier notifier) {
    if (state.isLoading && state.groupedDevices.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.isLoading && state.groupedDevices.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No Record Found',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: state.groupedDevices.length,
      itemBuilder: (context, index) {
        return _buildGroup(state.groupedDevices[index], state, notifier);
      },
    );
  }

  Widget _buildGroup(
    DeviceGroup group,
    DeviceState state,
    DeviceNotifier notifier,
  ) {
    final isExpanded = state.expandedGroups.contains(
      group.plantOrganizationCode,
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (_) =>
              notifier.toggleGroup(group.plantOrganizationCode),
          title: Text(
            group.siteName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          children: group.devices
              .map((device) => _buildDeviceCard(device, notifier))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Device device, DeviceNotifier notifier) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.deviceId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: primary),
                      onPressed: () => _showAddModal(device),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Device'),
                            content: const Text(
                              'Are you sure you want to delete this device?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await notifier.deleteDevice(device.id);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow('Plant', device.siteName ?? '-'),
            _infoRow('Address', device.siteInformation?.fullAddress ?? '-'),
            _infoRow('Tank', device.tankName ?? '-'),
            _infoRow('Category', device.category ?? '-'),
            _infoRow('Sim Number', device.simNumber ?? '-'),
            _infoRow('Time Zone', device.timeZone ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 11),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 16),
            onPressed: () =>
                ref.read(deviceProvider.notifier).loadGroupedDevices(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
