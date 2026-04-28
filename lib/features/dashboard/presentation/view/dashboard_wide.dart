import 'dart:async';

import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/network/mqtt/models/mqtt_connection_state.dart';
import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import '../../../auth/presentation/controllers/auth_providers.dart';
import '../../data/tank_data_model.dart';
import '../../provider/dashboard_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/site_group_model.dart';


class DashboardWide extends ConsumerStatefulWidget {
  const DashboardWide({super.key});

  @override
  ConsumerState<DashboardWide> createState() => _DashboardWideState();
}

class _DashboardWideState extends ConsumerState<DashboardWide> {
  final String tankStatusTopic = 'tweet/864180050620884';
  bool _isDisposed = false;

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Status';
  bool _isListView = true;
  String _selectedRegion = 'All Regions';

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Track subscribed topics to avoid duplicate subscriptions
  final Set<String> _subscribedTopics = {};

  @override
  void initState() {
    super.initState();

    // Only do initialization that doesn't require ref.listen
    // We'll handle subscription after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupMqttSubscription(); // This will handle subscription only, not listen
    });

    _addSampleMarkers();
  }

  void _setupMqttSubscription() {
    if (!_subscribedTopics.contains(tankStatusTopic)) {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      mqttNotifier.subscribeToTopic(tankStatusTopic);
      _subscribedTopics.add(tankStatusTopic);
      print('Subscribed to MQTT topic: $tankStatusTopic');
    }
  }

  void _handleMqttMessage(MqttMessageModel message) {
    try {
      // Parse the MQTT message using rawPayload string
      final parsedData = parseMqtt(message.rawPayload);
      print('Received MQTT update: $parsedData');

      // Update the tank data
      final tankNotifier = ref.read(tankDataListProvider.notifier);
      tankNotifier.updateFromMqtt(parsedData);

      // Update markers if needed (for map view)
      _updateMarkerFromMqtt(parsedData);

    } catch (e) {
      print('Error handling MQTT message: $e');
    }
  }

  void _updateMarkerFromMqtt(Map<String, dynamic> mqttData) {
    final deviceId = mqttData['deviceId'] as String?;
    if (deviceId == null) return;

    // Find the tank and update its marker
    final tanksAsync = ref.read(tankDataListProvider);
    tanksAsync.whenData((tanks) {
      final tank = tanks.firstWhere(
            (t) => t.deviceId == deviceId,
        orElse: () => null as TankDataModel,
      );

      if (mounted) {
        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value == deviceId);
          _markers.add(
            Marker(
              markerId: MarkerId(deviceId),
              position: LatLng(tank.latitude, tank.longitude),
              infoWindow: InfoWindow(
                title: tank.tankName,
                snippet: 'Level: ${tank.level.toStringAsFixed(1)}% | Status: ${tank.status}',
              ),
            ),
          );
        });
      }
    });
  }

  Map<String, dynamic> parseMqtt(String raw) {
    print('Raw MQTT message: $raw');

    String? deviceId;
    double? level;
    double? pressure;
    double? battery;
    double? solar;

    // Extract device ID from cC field
    final cCMatch = RegExp(r'cC:\s*([0-9]+)').firstMatch(raw);
    if (cCMatch != null) {
      deviceId = cCMatch.group(1);
      print('Found deviceId: $deviceId');
    }

    // Extract the cM field content (everything between cM: and , cL:)
    final cMMatch = RegExp(r'cM:\s*([^,]+?)(?:,\s*cL:)').firstMatch(raw);
    if (cMMatch != null) {
      final cMContent = cMMatch.group(1)!;
      print('cM Content: $cMContent');

      // Now parse the colon-separated values in cM content
      // Split by spaces to get individual key-value pairs
      final parts = cMContent.split(' ');

      for (var part in parts) {
        if (part.contains(':')) {
          final colonIndex = part.indexOf(':');
          final key = part.substring(0, colonIndex).trim();
          var value = part.substring(colonIndex + 1).trim();

          // Remove trailing colon if present (like in "TNP:100:")
          if (value.endsWith(':')) {
            value = value.substring(0, value.length - 1);
          }


          switch (key) {
            case 'TNP':
              level = double.tryParse(value);
              break;
            case 'PTN':
              pressure = double.tryParse(value);
              break;
            case 'BAT':
              battery = double.tryParse(value);
              break;
            case 'SOL':
              solar = double.tryParse(value);
              break;
          }
        }
      }
    }

    final result = {
      "deviceId": deviceId,
      "level": level,
      "pressure": pressure,
      "battery": battery,
      "solar": solar,
    };

    print('Parsed result: $result');
    return result;
  }


  void _addSampleMarkers() {
    // This will be populated from actual data when loaded
    final tanksAsync = ref.read(tankDataListProvider);
    tanksAsync.whenData((tanks) {
      for (var tank in tanks) {
        _markers.add(
          Marker(
            markerId: MarkerId(tank.deviceId),
            position: LatLng(tank.latitude, tank.longitude),
            infoWindow: InfoWindow(
              title: tank.tankName,
              snippet: 'Level: ${tank.level.toStringAsFixed(1)}% | Status: ${tank.status}',
            ),
          ),
        );
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final userNameAsync = ref.watch(userNameProvider);
    final userName = userNameAsync.value ?? 'User';

    // Watch the tank data
    final tanksDataAsync = ref.watch(tankDataListProvider);
    final statistics = ref.watch(tankStatisticsProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);

    // ✅ CORRECT: ref.listen called directly in build method
    ref.listen<AsyncValue<MqttMessageModel>>(
      mqttTopicStreamProvider(tankStatusTopic),
          (previous, next) {
        next.whenData((message) {
          _handleMqttMessage(message);
        });
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: tanksDataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load tank data',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(tankDataListProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tanksData) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(userName),
                const SizedBox(height: 24),
                _buildStatsCards(statistics),
                const SizedBox(height: 24),
                _buildDeviceListHeader(),
                const SizedBox(height: 16),
                _buildSearchAndFilters(),
                const SizedBox(height: 24),
                _buildViewToggle(),
                const SizedBox(height: 16),
                _isListView
                    ? _buildListView(groupedTanks, tanksData)
                    : _buildMapView(tanksData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String userName) {
    final connectionState = ref.watch(mqttProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $userName!',
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
        return tank.tankName.toLowerCase().contains(searchLower) ||
            tank.siteName.toLowerCase().contains(searchLower);
      }

      return true;
    }).toList();
  }


  Widget _buildListView(List<SiteGroupModel> groupedTanks, List<TankDataModel> allTanks) {
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
          return tank.tankName.toLowerCase().contains(searchLower) ||
              tank.siteName.toLowerCase().contains(searchLower);
        }

        return true;
      }).toList();

      return SiteGroupModel(
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
                Expanded(child: Text('SITE-TANK NAME', style: _headerStyle())),
                SizedBox(width: 200, child: Text('DEVICE ID', style: _headerStyle())),
                Expanded(child: Text('LEVEL', style: _headerStyle(), textAlign: TextAlign.center)),
                SizedBox(width: 100, child: Text('PRESSURE', style: _headerStyle(), textAlign: TextAlign.center)),
                SizedBox(width: 100, child: Text('BATTERY', style: _headerStyle(), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('SOLAR', style: _headerStyle(), textAlign: TextAlign.center)),
                SizedBox(width: 130,child: Text('STATUS', style: _headerStyle(), textAlign: TextAlign.center)),
                SizedBox(width: 150,child: Text('LAST UPDATE', style: _headerStyle(), textAlign: TextAlign.center)),
                const SizedBox(width: 45),
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

  Widget _buildSiteGroup(SiteGroupModel site) {
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
              Text(
                site.siteName,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
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
                tank.tankName,
                style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                Icon(Icons.opacity, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  tank.deviceId,
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
                  '${tank.level.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _getLevelColor(tank.level),
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tank.level / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: _getLevelColor(tank.level),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                '${tank.pressure.toStringAsFixed(1)} bar',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _getBatSolColor(tank.batteryV),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                '${tank.batteryV.toStringAsFixed(1)} v',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _getBatSolColor(tank.batteryV),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: Text(
                '${tank.solarV.toStringAsFixed(1)} v',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _getBatSolColor(tank.solarV),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
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
          SizedBox(
            width: 150,
            child: Center(
              child: Text(
                _formatDateTime(tank.lastUpdate),
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ),
          SizedBox(
            width: 45,
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

  Color _getBatSolColor(double level) {
    if (level <= 3) return Colors.red;
    if (level <= 7) return Colors.orange;
    return Colors.green;
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

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();

    // Unsubscribe from MQTT topics
    try {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      for (var topic in _subscribedTopics) {
        mqttNotifier.unsubscribeFromTopic(topic);
      }
      _subscribedTopics.clear();
    } catch (e) {
      // Ignore errors during disposal
      print('Error during MQTT cleanup: $e');
    }

    super.dispose();
  }

}