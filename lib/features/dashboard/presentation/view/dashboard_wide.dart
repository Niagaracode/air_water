import 'package:air_water/features/tank/presentation/view/tank_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/network/mqtt/providers/mqtt_notifier.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import '../../data/models/tank_data_model.dart';
import '../../provider/dashboard_provider.dart';

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
  final String topic = 'tweet';

  late final MqttNotifier mqttNotifier;

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All Status';
  String _selectedRegion = 'All Regions';
  String _searchQuery = '';
  int _filteredCount = 0;
  bool _isListView = true;

  @override
  void initState() {
    super.initState();

    mqttNotifier = ref.read(mqttProvider.notifier);

    Future.microtask(() {

      if (!mounted) return;

      Future.microtask(() async {
        if (!mounted) return;

        await mqttNotifier.initializeAndConnect();

        await mqttNotifier.subscribeToTopic(
          topic,
          onMessage: (msg) {
            print("✅ MQTT MESSAGE: ${msg.rawPayload}");

            final parsed = _parseMqtt(msg.data);

            if (!mounted) return;
            ref.read(tankDataProvider.notifier).updateFromMqtt(parsed);
          },
        );
      });

    });
  }


  Map<String, dynamic> _parseMqtt(Map<String, dynamic> json) {
    final result = <String, dynamic>{};

    // ✅ deviceId
    result['deviceId'] = json['cC'];

    // ✅ extract cM string
    final cM = json['cM'] ?? '';

    final matches = RegExp(r'([A-Z]+):([\d.]+)').allMatches(cM);

    for (var m in matches) {
      final key = m.group(1);
      final value = double.tryParse(m.group(2)!);

      switch (key) {
        case 'TNP':
          result['level'] = value;
          break;
        case 'PTN':
          result['pressure'] = value;
          break;
        case 'BAT':
          result['battery'] = value;
          break;
        case 'SOL':
          result['solar'] = value;
          break;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tankDataProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);
    final statistics = ref.watch(tankStatisticsProvider);

    return Scaffold(
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      body: tanksAsync.when(
        loading: () => _buildLoadingView(),
        error: (error, _) => Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                getErrorMessage(error),
                style: const TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(tankDataProvider.notifier).refresh();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (tanks) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Statistics
                StatisticsCards(
                  statistics: statistics,
                ),

                const SizedBox(height: 24),

                /// Header
                const DeviceListHeader(),

                const SizedBox(height: 12),

                /// Search & Filters
                SearchAndFilters(
                  onSearchChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  onRegionChanged: (val) {
                    setState(() {
                      _selectedRegion = val;
                    });
                  },
                  onStatusChanged: (val) {
                    setState(() {
                      _selectedStatus = val;
                    });
                  },
                  onClearFilters: () {
                    setState(() {
                      _selectedRegion = 'All Regions';
                      _selectedStatus = 'All Status';
                      _searchQuery = '';
                      _filteredCount = 0;
                    });
                    _searchController.clear();
                  },
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                ),

                const SizedBox(height: 16),

                /// Toggle
                ViewToggle(
                  currentView: _isListView
                      ? ViewType.list
                      : ViewType.map,

                  onViewChanged: (val) {
                    setState(() {
                      _isListView = val == ViewType.list;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// Main View
                _isListView ? DashboardListView(
                  groupedTanks: groupedTanks,
                  filteredTanks: tanks,
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  searchQuery: _searchQuery,
                  onMenuTap: _handleMenuTap,
                ) : DashboardMapView(
                  tanksData: tanks,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String getErrorMessage(dynamic error) {
    final msg = error.toString();
    if (msg.contains('SocketException')) {
      return 'No internet connection';
    } else if (msg.contains('TimeoutException')) {
      return 'Server timeout. Please try again';
    } else if (msg.contains('401')) {
      return 'Unauthorized access';
    } else if (msg.contains('500')) {
      return 'Internal server error';
    }

    return 'Unable to load data';
  }

  Widget _buildLoadingView() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5,
                    (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index != 4 ? 16 : 0,
                    ),
                    child: _skeletonBox(height: 60),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            /// Header
            _skeletonBox(width: 250, height: 28, radius: 8),
            const SizedBox(height: 20),
            /// Search Filters
            Row(
              children: [
                Expanded(flex: 3, child: _skeletonBox(height: 42)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _skeletonBox(height: 42)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _skeletonBox(height: 42)),
                const SizedBox(width: 16),
                _skeletonBox(width: 40, height: 42),
              ],
            ),
            const SizedBox(height: 20),
            /// Toggle
            Row(
              children: [
                _skeletonBox(width: 120, height: 34),
                const SizedBox(width: 12),
                _skeletonBox(width: 120, height: 34),
              ],
            ),
            const SizedBox(height: 24),
            /// Device Cards
            ...List.generate(6,
                  (index) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _skeletonBox(width: 40, height: 20),
                    const SizedBox(width: 8),
                    Expanded(child: _skeletonBox(height: 20)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({
    double? width,
    double height = 16,
    double radius = 12,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  void _handleMenuTap(TankDataModel tank, String action) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TankDetailsView(tankId: tank.id),
          ),
        );
        break;
      case 'edit':
        break;
      case 'alerts':
        break;
      case 'history':
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    //mqttNotifier.unsubscribeFromTopic(topic);
    super.dispose();
  }
}