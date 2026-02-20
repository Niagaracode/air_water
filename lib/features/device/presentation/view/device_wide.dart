import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/app_theme/app_theme.dart';
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

    // Sync controllers
    if (state.searchPlant != _plantSearchController.text &&
        state.searchPlant.isEmpty) {
      _plantSearchController.text = '';
    }
    if (state.searchDevice != _searchController.text &&
        state.searchDevice.isEmpty) {
      _searchController.text = '';
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEVICE MANAGEMENT',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Centralize Device Information Including Identification, Configuration, Connectivity, And Status Management.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddModal(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('ADD'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildDeviceAutocomplete(notifier)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPlantAutocomplete(notifier)),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _plantSearchController.clear();
                            notifier.clearFilters();
                          },
                          child: const Text('CLEAR'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Showing ${state.totalEntries} entries',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (state.isLoading && state.groupedDevices.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (state.error != null)
            SliverToBoxAdapter(child: Center(child: Text(state.error!)))
          else
            _buildVirtualizedTable(state, notifier),
          if (state.isLoading && state.groupedDevices.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Please wait loading new record',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(DeviceState state, DeviceNotifier notifier) {
    if (state.groupedDevices.isEmpty && !state.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Center(
            child: Text(
              'No Record Found',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _tableHeaderCell('SI.NO', width: 70),
                  _tableHeaderCell('Date', flex: 2),
                  _tableHeaderCell('Device ID', flex: 2),
                  _tableHeaderCell('Company', flex: 2),
                  _tableHeaderCell('Category', flex: 2),
                  _tableHeaderCell('Sim Number', flex: 2),
                  _tableHeaderCell('Notes', flex: 3),
                  _tableHeaderCell('Tank', flex: 2),
                  _tableHeaderCell('Time Zone', flex: 2),
                  _tableHeaderCell('Status', flex: 2),
                  _tableHeaderCell('Action', width: 100),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: state.groupedDevices.length,
            itemBuilder: (context, index) {
              final group = state.groupedDevices[index];
              final isExpanded = state.expandedGroups.contains(
                group.plantOrganizationCode,
              );

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade200),
                    right: BorderSide(color: Colors.grey.shade200),
                    bottom: index == state.groupedDevices.length - 1
                        ? BorderSide(color: Colors.grey.shade200)
                        : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    // Site Header Row
                    Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () =>
                            notifier.toggleGroup(group.plantOrganizationCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade100),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70,
                                child: Center(
                                  child: Text(
                                    (index + 1).toString().padLeft(2, '0'),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.siteName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (group.devices.isNotEmpty &&
                                        group.devices.first.siteInformation !=
                                            null)
                                      Text(
                                        group
                                            .devices
                                            .first
                                            .siteInformation!
                                            .fullAddress,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 12),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Device Rows
                    if (isExpanded)
                      ...group.devices.map(
                        (device) => _buildDeviceRow(device, notifier),
                      ),
                  ],
                ),
              );
            },
          ),
          if (state.groupedDevices.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: Colors.grey.shade200),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(Device device, DeviceNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 70),
          _tableCell(device.createdAt?.split('T')[0] ?? '-', flex: 2),
          _tableCell(device.deviceId, flex: 2),
          _tableCell(device.companyName ?? '-', flex: 2),
          _tableCell(device.category ?? '-', flex: 2),
          _tableCell(device.simNumber ?? '-', flex: 2),
          _tableCell(device.notes ?? '-', flex: 3),
          _tableCell(device.tankName ?? '-', flex: 2),
          _tableCell(device.timeZone ?? '-', flex: 2),
          Expanded(
            flex: 2,
            child: Center(child: _buildStatusChip(device.status)),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _showAddModal(device),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                _buildDeleteButton(device, notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(Device device, DeviceNotifier notifier) {
    return IconButton(
      onPressed: () async {
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
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
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
      },
      icon: const Icon(Icons.delete_outline, size: 20),
      color: Colors.red,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildStatusChip(int status) {
    final isActive = status == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tableHeaderCell(String label, {int? flex, double? width}) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
  }

  Widget _tableCell(
    String value, {
    int? flex,
    double? width,
    TextStyle? style,
  }) {
    final cell = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        value,
        style: style ?? const TextStyle(fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );

    if (width != null) return SizedBox(width: width, child: cell);
    return Expanded(flex: flex ?? 1, child: cell);
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
            return Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Filter By Plant Name',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (v) {
                  notifier.setSearchPlant(v);
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
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          option.fullAddress,
                          style: const TextStyle(fontSize: 11),
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
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Search By Device ID / Name',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                          style: const TextStyle(fontSize: 13),
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
}

class RoundedRectangleAt extends OutlinedBorder {
  const RoundedRectangleAt({super.side, this.borderRadius = BorderRadius.zero});

  final BorderRadiusGeometry borderRadius;

  @override
  OutlinedBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) {
    return RoundedRectangleAt(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(
      borderRadius.resolve(textDirection).toRRect(rect).deflate(side.width),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return;
    final RRect rrect = borderRadius.resolve(textDirection).toRRect(rect);
    canvas.drawRRect(rrect, side.toPaint());
  }

  @override
  ShapeBorder scale(double t) {
    return RoundedRectangleAt(
      side: side.scale(t),
      borderRadius: borderRadius * t,
    );
  }
}
