import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/tank/presentation/view/tank_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/network/mqtt/models/mqtt_message.dart';
import '../../../../core/network/mqtt/providers/mqtt_notifier.dart';
import '../../../../core/network/mqtt/providers/mqtt_providers.dart';
import '../../data/models/tank_data_model.dart';
import '../../provider/dashboard_provider.dart';

import '../widgets/dashboard_list_view.dart';
import '../widgets/dashboard_map_view.dart';
import '../widgets/search_and_filters.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/view_toggle.dart';

import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xls;
import 'package:pdf/widgets.dart' as pw;


class DashboardWide extends ConsumerStatefulWidget {
  const DashboardWide({super.key});


  @override
  ConsumerState<DashboardWide> createState() => _DashboardWideState();
}

class _DashboardWideState extends ConsumerState<DashboardWide> {
  final String topic = 'tweet';
  late final MqttNotifier mqttNotifier;
  late final Function(MqttMessageModel) _mqttCallback;

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All Status';
  String _selectedRegion = 'All Regions';
  String _searchQuery = '';
  bool _isListView = true;

  @override
  void initState() {
    super.initState();
    mqttNotifier = ref.read(mqttProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {

    await mqttNotifier.initializeAndConnect();

    if (!mounted) return;

    _mqttCallback = (msg) {
      if (!mounted) return;
      print("✅ MQTT MESSAGE: ${msg.rawPayload}");
      final parsed = _parseMqtt(msg.data);
      ref.read(tankDataProvider.notifier)
          .updateFromMqtt(parsed);
    };

    /// Always subscribe again
    await mqttNotifier.subscribeToTopic(
      topic,
      onMessage: _mqttCallback,
    );
  }


  Map<String, dynamic> _parseMqtt(Map<String, dynamic> json) {
    final result = <String, dynamic>{};

    result['deviceId'] = json['cC'];
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
          result['batteryV'] = value;
          break;

        case 'SOL':
          result['solarV'] = value;
          break;
      }
    }

    /// Parse date + time
    final date = json['cD']?.toString().trim() ?? '';
    final time = json['cT']?.toString().trim() ?? '';

    if (date.isNotEmpty && time.isNotEmpty) {
      try {
        result['lastUpdate'] = DateFormat('dd/MM/yyyy HH:mm:ss')
                .parse('$date $time');
      } catch (_) {
        result['lastUpdate'] = DateTime.now();
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

                const SizedBox(height: 30),

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
                    });
                    _searchController.clear();
                  },
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                ),

                const SizedBox(height: 16),

                /// Toggle
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ViewToggle(
                      currentView: _isListView ? ViewType.list : ViewType.map,
                      onViewChanged: (val) {
                        setState(() {
                          _isListView = val == ViewType.list;
                        });
                      },
                    ),
                    Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Download Report',
                      onSelected: (value) async {
                        final tanks = ref.read(tankDataProvider).value ?? [];

                        if (value == 'excel') {
                          await exportToExcel(tanks);
                        }

                        if (value == 'pdf') {
                          await exportToPdf(tanks);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart_outlined, color: primary),
                              SizedBox(width: 10),
                              Text('Download Excel'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf_outlined, color: primary),
                              SizedBox(width: 10),
                              Text('Download PDF'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18, color: primary),
                            SizedBox(width: 8),
                            Text('Download', style: TextStyle(color: primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// Main View
                _isListView ? DashboardListView(
                  groupedTanks: groupedTanks,
                  filteredTanks: tanks,
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  searchQuery: _searchQuery,
                  onTankTap: _callDetailsPage,
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

  void _callDetailsPage(TankDataModel tank) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TankDetailsView(tankId: tank.id, tank: tank),
      ),
    );
  }

  Future<void> exportToExcel(
      List<TankDataModel> tanks,
      ) async {

    final workbook = xls.Workbook();

    final sheet = workbook.worksheets[0];

    /// Header
    sheet.getRangeByName('A1').setText('Tank Name');
    sheet.getRangeByName('B1').setText('Site');
    sheet.getRangeByName('C1').setText('Level');
    sheet.getRangeByName('D1').setText('Pressure');
    sheet.getRangeByName('E1').setText('Battery');
    sheet.getRangeByName('F1').setText('Solar');
    sheet.getRangeByName('G1').setText('Status');

    /// Data
    for (int i = 0; i < tanks.length; i++) {
      final row = i + 2;
      final tank = tanks[i];

      sheet.getRangeByName('A$row').setText(tank.tankName);
      sheet.getRangeByName('B$row').setText(tank.siteName);
      sheet.getRangeByName('C$row').setNumber(tank.level);
      sheet.getRangeByName('D$row').setNumber(tank.pressure);
      sheet.getRangeByName('E$row').setNumber(tank.batteryV);
      sheet.getRangeByName('F$row').setNumber(tank.solarV);
      sheet.getRangeByName('G$row').setText(tank.status);
    }

    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);
    sheet.autoFitColumn(6);
    sheet.autoFitColumn(7);

    final List<int> bytes = workbook.saveAsStream();

    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: 'tank_report',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<void> exportToPdf(
      List<TankDataModel> tanks,
      ) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [

          pw.Text(
            'Tank Report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: [
              'Tank',
              'Level',
              'Pressure',
              'Battery',
              'Solar',
              'Status',
            ],
            data: tanks.map((tank) {
              return [
                tank.tankName,
                tank.level.toString(),
                tank.pressure.toString(),
                tank.batteryV.toString(),
                tank.solarV.toString(),
                tank.status,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    await FileSaver.instance.saveFile(
      name: 'tank_report',
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

}