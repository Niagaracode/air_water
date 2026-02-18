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
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DEVICE MANAGEMENT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showAddModal(),
                      child: const Text('ADD'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
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
                    notifier.loadGroupedDevices(deviceId: value);
                  },
                ),
                const SizedBox(height: 12),
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
}
