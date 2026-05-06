import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/mqtt/providers/mqtt_notifier.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
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
  final String topic = 'tweet/864180050620884';

  late final MqttNotifier mqttNotifier;

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All Status';
  String _selectedRegion = 'All Regions';
  String _searchQuery = '';
  bool _isListView = true;

  ViewType get _currentViewType =>
      _isListView ? ViewType.list : ViewType.map;

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
      backgroundColor: Colors.grey.withOpacity(0.1),
      body: tanksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, _) => Center(
          child: ElevatedButton(
            onPressed: () {
              ref.read(tankDataProvider.notifier).refresh();
            },
            child: const Text("Retry"),
          ),
        ),

        data: (tanks) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 📊 Stats
                StatisticsCards(statistics: statistics),
                const SizedBox(height: 24),

                /// Header
                const DeviceListHeader(),
                const SizedBox(height: 12),

                /// Filters
                SearchAndFilters(
                  onSearchChanged: (val) {setState(() => _searchQuery = val);},
                  onRegionChanged: (val) {setState(() => _selectedRegion = val);},
                  onStatusChanged: (val) {setState(() => _selectedStatus = val);},
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

                const SizedBox(height: 16),

                /// Toggle
                ViewToggle(
                  currentView: _currentViewType,
                  onViewChanged: (val) {
                    setState(() {
                      _isListView = val == ViewType.list;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// View
                _isListView
                    ? DashboardListView(
                  groupedTanks: groupedTanks,
                  filteredTanks: tanks,
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  searchQuery: _searchQuery,
                ) : DashboardMapView(tanksData: tanks),
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
    //mqttNotifier.unsubscribeFromTopic(topic);
    super.dispose();
  }
}