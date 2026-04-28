import 'dart:async';

import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/network/mqtt/models/mqtt_connection_state.dart';
import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import '../../../../core/user_config/user_role.dart';
import '../../../../core/user_config/user_role_provider.dart';
import 'package:air_water/features/alarm/presentation/controller/alarm_provider.dart';
import 'package:air_water/features/tank/presentation/controller/tank_provider.dart';
import '../../domain/dashboard_repository.dart';
import '../model/alarm_model.dart';
import '../model/tank_data_model.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/technician_dashboard.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ============ PROVIDERS ============
// Provider for grouped tanks
final groupedTanksProvider = Provider<List<SiteGroup>>((ref) {
  final tanks = ref.watch(tankProviderDashboard);
  final tankNotifier = ref.read(tankProviderDashboard.notifier);
  return tankNotifier.getGroupedTanks();
});

// Provider for statistics
final tankStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final tankNotifier = ref.read(tankProviderDashboard.notifier);
  return tankNotifier.getStatistics();
});

// Provider for filtered tanks by region
final regionFilteredTanksProvider = Provider.family<List<TankDataModel>, String>((ref, region) {
  final tankNotifier = ref.read(tankProviderDashboard.notifier);
  return tankNotifier.getTanksByRegion(region);
});
// ============ END PROVIDERS ============

class DashboardWide extends ConsumerStatefulWidget {
  const DashboardWide({super.key});

  @override
  ConsumerState<DashboardWide> createState() => _DashboardWideState();
}

class _DashboardWideState extends ConsumerState<DashboardWide> {
  final String tankStatusTopic = 'tweet/864180050620884';

  StreamSubscription<MqttMessageModel>? _tankSubscription;

  // Flag to track if widget is disposed
  bool _isDisposed = false;

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Status';
  bool _isListView = true;
  String _selectedRegion = 'All Regions';

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _setupSubscriptions();
      }
    });

    _addSampleMarkers();
  }


  void _setupSubscriptions() {
    // Capture ref before async operations
    final refAtCallTime = ref;

    Future.delayed(Duration(seconds: 2), () {
      if (mounted && !_isDisposed) {
        final mqttNotifier = refAtCallTime.read(mqttProvider.notifier);
        mqttNotifier.subscribeToTopic(tankStatusTopic);
      }
    });

  }

  void _addSampleMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('tank1'),
        position: const LatLng(11.0168, 76.9558),
        infoWindow: const InfoWindow(title: 'Water Tank', snippet: 'Active'),
      ),
    );
  }

  void _startPeriodicPublishing() {
    if (_isDisposed) return;

    final refAtCallTime = ref;

    if (mounted && !_isDisposed) {
      try {
        final mqttNotifier = refAtCallTime.read(mqttProvider.notifier);
        mqttNotifier.publishMessage('get-tweet-response/karthik', {
          "data": 'kamaraj',
          "timestamp": DateTime.now().toIso8601String(),
        });
        debugPrint('📤 Published message at ${DateTime.now()}');
      } catch (e) {
        debugPrint('Error publishing: $e');
      }
    }
  }

  void _handleStreamData(AsyncValue<MqttMessageModel> tankStream) {
    // Handle tank status updates
    tankStream.whenData((message) {
      if (mounted && !_isDisposed) {
        _handleTankStatusUpdate(message);
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    // Safely watch streams
    final tankStatusStream = ref.watch(mqttTopicStreamProvider(tankStatusTopic));

    // Handle stream data safely
    // Listen to MQTT stream updates safely
    ref.listen(mqttTopicStreamProvider(tankStatusTopic), (previous, next) {
      next.whenData((message) {
        _handleTankStatusUpdate(message);
      });
    });

    final tanksData = ref.watch(tankProviderDashboard);
    final alarmsData = ref.watch(alarmProviderDashboard);
    final statistics = ref.watch(tankStatisticsProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Stats Cards with real data
            _buildStatsCards(statistics),
            const SizedBox(height: 24),

            // Device List Header with Actions
            _buildDeviceListHeader(),
            const SizedBox(height: 16),

            // Search and Filters
            _buildSearchAndFilters(),
            const SizedBox(height: 24),

            // Map/List View Toggle
            _buildViewToggle(),
            const SizedBox(height: 16),

            // Content based on view type
            _isListView
                ? _buildListView(groupedTanks)
                : _buildMapView(tanksData),
          ],
        ),
      ),
    );
  }



  Widget _buildConnectionStatus(MqttConnectionStateModel state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: state.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state.isConnected ? 'MQTT Connected' : 'MQTT Disconnected',
            style: TextStyle(
              color: state.isConnected ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final connectionState = ref.watch(mqttProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, John!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monitor your tank levels in real-time',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        _buildConnectionStatus(connectionState),
      ],
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> statistics) {
    final total = statistics['total'] ?? 0;
    final active = statistics['active'] ?? 0;
    final offline = statistics['offline'] ?? 0;
    final lowBattery = statistics['lowBattery'] ?? 0;
    final lowLevel = statistics['lowLevel'] ?? 0;
    final reorderLevel = statistics['reorder'] ?? 0;

    return Row(
      children: [
        // Active Devices - Soft Green
        _buildStatCard(
          title: 'Active Devices',
          value: '$active/$total',
          subtitle: 'Online',
          icon: Icons.devices,
          color: const Color(0xFFA7F3D0),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFA7F3D0),
              Color(0xFF6EE7B7),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Offline Devices - Soft Gray
        _buildStatCard(
          title: 'Offline Devices',
          value: '$offline/$total',
          subtitle: 'Offline',
          icon: Icons.offline_bolt,
          color: const Color(0xFFD1D5DB),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFD1D5DB),
              Color(0xFF9CA3AF),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Low Battery - Soft Yellow
        _buildStatCard(
          title: 'Low Battery',
          value: '$lowBattery/$total',
          subtitle: 'Needs Charging',
          icon: Icons.battery_alert,
          color: const Color(0xFFFDE68A),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFDE68A),
              Color(0xFFFBBF24),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Low Level - Soft Orange
        _buildStatCard(
          title: 'Low Level',
          value: '$lowLevel/$total',
          subtitle: 'Below Threshold',
          icon: Icons.water_drop,
          color: const Color(0xFFFED7AA),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFED7AA),
              Color(0xFFF97316),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Reorder Level - Soft Amber
        _buildStatCard(
          title: 'Reorder Level',
          value: '$reorderLevel/$total',
          subtitle: 'Need Restock',
          icon: Icons.inventory,
          color: const Color(0xFFFEF3C7),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFEF3C7),
              Color(0xFFFBBF24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.black.withValues(alpha: 0.7), size: 24),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Device List',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Implement search functionality
                if (mounted) {
                  setState(() {});
                }
              },
              decoration: InputDecoration(
                hintText: 'Search devices...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Region Filter
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedRegion,
            items: ['All Regions', 'Arizona', 'New Mexico', 'Texas', 'Oklahoma'],
            onChanged: (value) {
              if (mounted) {
                setState(() => _selectedRegion = value!);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        // Status Filter
        Expanded(
          child: _buildFilterDropdown(
            value: _selectedStatus,
            items: ['All Status', 'Active', 'Warning', 'Critical', 'Offline', 'Out of Order'],
            onChanged: (value) {
              if (mounted) {
                setState(() => _selectedStatus = value!);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        // Filters Button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141E7A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF141E7A)),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _selectedRegion = 'All Regions';
                  _selectedStatus = 'All Status';
                  _searchController.clear();
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item.toString(),
                style: GoogleFonts.outfit(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('List View', 0, Icons.list),
          const SizedBox(width: 4),
          _buildToggleButton('Map View', 1, Icons.map),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, int viewIndex, IconData icon) {
    final isSelected = (_isListView ? 0 : 1) == viewIndex;
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() => _isListView = viewIndex == 0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? const Color(0xFF141E7A) : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF141E7A) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(List<TankDataModel> tanksData) {
    final filteredTanks = _filterTanks(tanksData);

    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(11.0168, 76.9558),
            zoom: 12,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: _markers,
          myLocationEnabled: true,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }

  List<TankDataModel> _filterTanks(List<TankDataModel> tanks) {
    return tanks.where((tank) {
      // Region filter
      if (_selectedRegion != 'All Regions' && tank.region != _selectedRegion) {
        return false;
      }

      // Status filter
      if (_selectedStatus != 'All Status' && tank.status != _selectedStatus) {
        return false;
      }

      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        return tank.name.toLowerCase().contains(searchLower) ||
            tank.siteName.toLowerCase().contains(searchLower);
      }

      return true;
    }).toList();
  }


  Widget _buildListView(List<SiteGroup> groupedTanks) {
    // Filter groups based on search and filters
    final filteredGroups = groupedTanks.map((group) {
      final filteredTanks = group.tanks.where((tank) {
        // Region filter
        if (_selectedRegion != 'All Regions' && tank.region != _selectedRegion) {
          return false;
        }

        // Status filter
        if (_selectedStatus != 'All Status' && tank.status != _selectedStatus) {
          return false;
        }

        // Search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          return tank.name.toLowerCase().contains(searchLower) ||
              tank.siteName.toLowerCase().contains(searchLower);
        }

        return true;
      }).toList();

      return SiteGroup(
        siteName: group.siteName,
        siteLocation: group.siteLocation,
        tanks: filteredTanks,
      );
    }).where((group) => group.tanks.isNotEmpty).toList();

    if (filteredGroups.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No devices found',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text('SITE', style: _headerStyle())),
                Expanded(child: Text('TANK NAME', style: _headerStyle())),
                Expanded(child: Text('LEVEL', style: _headerStyle(), textAlign: TextAlign.center)),
                Expanded(child: Text('STATUS', style: _headerStyle(), textAlign: TextAlign.center)),
                Expanded(child: Text('LAST UPDATE', style: _headerStyle(), textAlign: TextAlign.center)),
                const SizedBox(width: 50),
              ],
            ),
          ),

          // Table Body
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final site = filteredGroups[index];
              return _buildSiteGroup(site);
            },
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 1,
    );
  }

  Widget _buildSiteGroup(SiteGroup site) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Site Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFF141E7A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  site.siteName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF141E7A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${site.tanks.length} tanks',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF141E7A),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tanks
        ...site.tanks.map((tank) => _buildTankRow(tank)),
      ],
    );
  }

  Widget _buildTankRow(TankDataModel tank) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                tank.siteName,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.opacity, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  tank.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${(tank.level ?? 0.0).toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _getLevelColor(tank.level ?? 0.0),
                  ),
                ),
                if (tank.ptn != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'PTN: ${tank.ptn!.toStringAsFixed(1)}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (tank.level ?? 0.0) / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: _getLevelColor(tank.level ?? 0.0),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(tank.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getStatusColor(tank.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tank.status,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(tank.status),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                tank.lastUpdate != null ? _formatDateTime(tank.lastUpdate!) : 'Never',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'alerts', child: Text('Set Alerts')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(double level) {
    if (level <= 20) return Colors.red;
    if (level <= 40) return Colors.orange;
    return Colors.green;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      case 'offline':
        return Colors.grey;
      case 'out of order':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _handleTankStatusUpdate(MqttMessageModel message) {
    debugPrint('📊 Tank Status Update: ${message.data}');
    // Update your UI or provider here
    if (mounted) {
      // Example: Update tank level in provider
      // ref.read(tankProvider.notifier).updateTankLevel(message.data);
    }
  }



  @override
  void dispose() {
    _isDisposed = true;

    // Dispose controllers
    _searchController.dispose();

    // Unsubscribe from MQTT topics (only if needed)
    // Note: The provider will handle cleanup, but we can explicitly unsubscribe
    try {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.unsubscribeFromTopic(tankStatusTopic);
    } catch (e) {
      // Ignore errors during disposal
    }

    super.dispose();
  }
}