import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
import '../controller/device_provider.dart';
import '../model/device_model.dart';
import '../widgets/add_device_modal.dart';

class DeviceMiddle extends ConsumerStatefulWidget {
  const DeviceMiddle({super.key});

  @override
  ConsumerState<DeviceMiddle> createState() => _DeviceMiddleState();
}

class _DeviceMiddleState extends ConsumerState<DeviceMiddle> {
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(notifier),
                  const SizedBox(height: 16),
                  if (state.error != null) _buildErrorBanner(state.error!),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildVirtualizedList(state, notifier),
          ),
          if (state.isLoading && state.groupedDevices.isNotEmpty)
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
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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

  Widget _buildHeader(DeviceNotifier notifier) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DEVICE MANAGEMENT',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () => _showAddModal(),
              child: const Text('ADD'),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Please wait loading new record',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.isLoading && state.groupedDevices.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              'No Record Found',
              style: TextStyle(color: Colors.grey, fontSize: 13),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) =>
            notifier.toggleGroup(group.plantOrganizationCode),
        title: Text(
          group.siteName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: group.devices.isNotEmpty
            ? Text(
                '${group.devices.first.siteInformation?.fullAddress ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              )
            : null,
        children: group.devices
            .map((device) => _buildDeviceItem(device, notifier))
            .toList(),
      ),
    );
  }

  Widget _buildDeviceItem(Device device, DeviceNotifier notifier) {
    return ListTile(
      title: Text(device.deviceId),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plant: ${device.siteName ?? '-'} (${device.siteInformation?.fullAddress ?? ''})',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            'Tank: ${device.tankName ?? '-'} | Category: ${device.category ?? '-'} | Sim: ${device.simNumber ?? '-'}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: primary),
            onPressed: () => _showAddModal(device),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
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
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
            onPressed: () =>
                ref.read(deviceProvider.notifier).loadGroupedDevices(),
          ),
        ],
      ),
    );
  }
}
