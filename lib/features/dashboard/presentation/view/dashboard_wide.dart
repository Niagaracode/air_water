import 'package:air_water/features/tank/presentation/view/tank_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import '../../data/tank_data_model.dart';
import '../../provider/dashboard_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/dashboard_list_view.dart';
import '../widgets/dashboard_map_view.dart';
import '../widgets/device_list_header.dart';
import '../widgets/search_and_filters.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/view_toggle.dart';

class DashboardWide extends ConsumerStatefulWidget {
  const DashboardWide({super.key});

  @override
  ConsumerState<DashboardWide> createState() => _DashboardWideState();
}

class _DashboardWideState extends ConsumerState<DashboardWide> {
  final String tankStatusTopic = 'tweet/864180050620884';

  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All Status';
  bool _isListView = true;
  String _selectedRegion = 'All Regions';
  String _searchQuery = '';

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Track subscribed topics to avoid duplicate subscriptions
  final Set<String> _subscribedTopics = {};

  ViewType get _currentViewType => _isListView ? ViewType.list : ViewType.map;

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
      // Parse the MQTT message
      final parsedData = parseMqtt(message.data.toString());
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
                snippet:
                    'Level: ${tank.level.toStringAsFixed(1)}% | Status: ${tank.status}',
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
              snippet:
                  'Level: ${tank.level.toStringAsFixed(1)}% | Status: ${tank.status}',
            ),
          ),
        );
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the tank data
    final tanksDataAsync = ref.watch(tankDataListProvider);
    final statistics = ref.watch(tankStatisticsProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Failed to load tank data',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
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
                const SizedBox(height: 10),
                StatisticsCards(statistics: statistics),
                const SizedBox(height: 24),
                const DeviceListHeader(),
                const SizedBox(height: 8),
                SearchAndFilters(
                  onSearchChanged: (String value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onRegionChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedRegion = value;
                      });
                    }
                  },
                  onStatusChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                  onClearFilters: () {
                    setState(() {
                      _selectedRegion = 'All Regions';
                      _selectedStatus = 'All Status';
                      _searchQuery = '';
                    });
                    _searchController.clear();
                  },
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                ),
                const SizedBox(height: 18),
                ViewToggle(
                  currentView: _currentViewType,
                  onViewChanged: (ViewType value) {
                    setState(() {
                      _isListView = value == ViewType.list;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _isListView
                    ? DashboardListView(
                        groupedTanks: groupedTanks,
                        filteredTanks: tanksData,
                      )
                    : DashboardMapView(tanksData: tanksData),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    try {
      final mqttNotifier = ref.read(mqttProvider.notifier);
      for (var topic in _subscribedTopics) {
        mqttNotifier.unsubscribeFromTopic(topic);
      }
      _subscribedTopics.clear();
    } catch (e) {
      print('Error during MQTT cleanup message: $e');
    }

    super.dispose();
  }
}
