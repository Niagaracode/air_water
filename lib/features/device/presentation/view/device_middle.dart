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

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(deviceProvider.notifier).loadGroupedDevices(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DEVICE MANAGEMENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showAddModal(),
                      child: const Text('ADD'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
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
                    notifier.loadGroupedDevices(deviceId: value);
                  },
                ),
                const SizedBox(height: 16),
                if (state.isLoading && state.groupedDevices.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  ...state.groupedDevices.map(
                    (group) => _buildGroup(group, state, notifier),
                  ),
              ],
            ),
          ),
        ],
      ),
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
}
