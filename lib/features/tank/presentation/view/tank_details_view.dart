import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controller/tank_details_provider.dart';
import '../model/tank_model.dart';
import '../model/tank_details_model.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/app_details_header.dart';
import '../../../../shared/widgets/app_metric_card.dart';
import '../../../../shared/widgets/app_asset_info_grid.dart';
import '../../../../shared/widgets/app_table_filter_popup.dart';
import '../widgets/tank_level_chart.dart';
import '../widgets/tank_diagram_widget.dart';
import '../controller/tank_provider.dart';

class TankDetailsView extends ConsumerStatefulWidget {
  final int tankId;
  final Tank? tank; // Pass from list for immediate title display

  const TankDetailsView({
    super.key,
    required this.tankId,
    this.tank,
  });

  @override
  ConsumerState<TankDetailsView> createState() => _TankDetailsViewState();
}

class _TankDetailsViewState extends ConsumerState<TankDetailsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _generateCountController = TextEditingController(text: '1');
  final TextEditingController _diameterController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _canLengthController = TextEditingController();
  final TextEditingController _dishDepthController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _coneLengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _dishHeightController = TextEditingController();
  final TextEditingController _tonnesController = TextEditingController();
  bool _useStrappingChart = true; // Default to true as per user request
  String _selectedLevelUnit = 'mm';
  String _selectedVolumeUnit = 'Cubic Meter';
  List<String> _unitOptions = ['mm', 'cm', 'm', 'ft', 'in', 'yd', 'Liter', 'Kilogram', 'Ton', 'Cubic Meter', 'Gallon'];
  List<StrappingPoint> _editPoints = [];

  int _saveVersion = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    if (widget.tank != null) {
      _descController.text = widget.tank!.description ?? '';
      _diameterController.text = widget.tank!.diameter?.toString() ?? '';
      _lengthController.text = widget.tank!.length?.toString() ?? '';
      _canLengthController.text = widget.tank!.canLength?.toString() ?? '';
      _dishDepthController.text = widget.tank!.dishDepth?.toString() ?? '';
      _depthController.text = widget.tank!.depth?.toString() ?? '';
      _coneLengthController.text = widget.tank!.coneLength?.toString() ?? '';
      _widthController.text = widget.tank!.width?.toString() ?? '';
      _heightController.text = widget.tank!.height?.toString() ?? '';
      _dishHeightController.text = widget.tank!.dishHeight?.toString() ?? '';
      _tonnesController.text = widget.tank!.tonnes?.toString() ?? '';
      _useStrappingChart = true; // Always display strapping chart as per user request
      _editPoints = List.from(widget.tank!.strappingPoints ?? []);
      if (_editPoints.isEmpty) {
        _editPoints = [StrappingPoint(levelMm: 0, volumeM3: 0)];
      }
    } else {
      _editPoints = [StrappingPoint(levelMm: 0, volumeM3: 0)];
    }
    Future.microtask(() {
      ref.read(tankDetailsProvider.notifier).loadData(widget.tankId);
      _loadDropdowns();
    });
  }

  Future<void> _loadDropdowns() async {
    try {
      final data = await ref.read(tankProvider.notifier).getDropdowns();
      final List units = data['units'] ?? [];
      if (units.isNotEmpty) {
        setState(() {
          _unitOptions = units.map((u) => u['name'].toString()).toList();
          
          if (_unitOptions.isNotEmpty && !_unitOptions.contains(_selectedLevelUnit)) {
            _selectedLevelUnit = _unitOptions.first;
          }
          if (_unitOptions.isNotEmpty && !_unitOptions.contains(_selectedVolumeUnit)) {
            _selectedVolumeUnit = _unitOptions.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load units: $e');
    }
  }

  void _initializeFromTank(Tank tank) {
    setState(() {
      _descController.text = tank.description ?? '';
      _diameterController.text = tank.diameter?.toString() ?? '';
      _lengthController.text = tank.length?.toString() ?? '';
      _canLengthController.text = tank.canLength?.toString() ?? '';
      _dishDepthController.text = tank.dishDepth?.toString() ?? '';
      _depthController.text = tank.depth?.toString() ?? '';
      _coneLengthController.text = tank.coneLength?.toString() ?? '';
      _widthController.text = tank.width?.toString() ?? '';
      _heightController.text = tank.height?.toString() ?? '';
      _dishHeightController.text = tank.dishHeight?.toString() ?? '';
      _tonnesController.text = tank.tonnes?.toString() ?? '';
      _useStrappingChart = true; // Always display strapping chart as per user request
      
      // Restore saved units if available
      if (tank.levelUnit != null && _unitOptions.contains(tank.levelUnit)) {
        _selectedLevelUnit = tank.levelUnit!;
      }
      if (tank.volumeUnit != null && _unitOptions.contains(tank.volumeUnit)) {
        _selectedVolumeUnit = tank.volumeUnit!;
      }

      // DO NOT load previous strapping points into the entry area
      // Always start with a clean 0 entry for new record addition as per user request
      _editPoints = [StrappingPoint(levelMm: 0, volumeM3: 0)];
      _saveVersion++; // Force reset of any leftover text in the fields
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    _generateCountController.dispose();
    _diameterController.dispose();
    _lengthController.dispose();
    _canLengthController.dispose();
    _dishDepthController.dispose();
    _depthController.dispose();
    _coneLengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _dishHeightController.dispose();
    _tonnesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tankDetailsProvider);
    final tankInfo = state.tank ?? widget.tank;

    // Listen to data loading to populate local state once (crucial for browser refresh)
    ref.listen<TankDetailsState>(tankDetailsProvider, (previous, next) {
      if (next.tank != null && previous?.tank == null) {
        _initializeFromTank(next.tank!);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          AppDetailsHeader(
            title: '${tankInfo?.plantName ?? 'Awaiting Data...'} Tank Nr: ${tankInfo?.tankNumber ?? ''}',
            subtitle: tankInfo?.description,
            breadcrumbs: [
              BreadcrumbItem(label: 'Home', onTap: () => context.go('/dashboard')),
              BreadcrumbItem(label: 'Data'),
              BreadcrumbItem(label: 'Tank Management', onTap: () => context.pop()),
              BreadcrumbItem(label: 'Tank Details', isCurrent: true),
            ],
            onBack: () => context.pop(),
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(state, tankInfo),
                _buildEventsTab(state),
                _buildReadingsTab(state),
                _buildForecastTab(state),
                _buildMapTab(state, tankInfo),
                _buildInformationTab(state, tankInfo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF141E7A),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF141E7A),
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Events'),
          Tab(text: 'Readings'),
          Tab(text: 'Forecast'),
          Tab(text: 'Map'),
          Tab(text: 'Information'),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(TankDetailsState state, Tank? tank) {
    if (state.isLoading) return const Center(child: AppLoader());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartCard(state),
          const SizedBox(height: 24),
          AppAssetInfoGrid(
            title: 'Asset Information',
            items: [
              AppInfoItemData(label: 'Plant', value: tank?.plantName ?? '—'),
              AppInfoItemData(label: 'Tank ID', value: tank?.tankNumber ?? '—'),
              AppInfoItemData(label: 'Status', value: tank?.status == 1 ? 'Active' : 'Inactive'),
              AppInfoItemData(label: 'Tank Type', value: tank?.tankTypeName ?? '—'),
              AppInfoItemData(label: 'Product', value: tank?.productName ?? '—'),
              AppInfoItemData(label: 'Last Sync', value: 'Today, 10:45 AM'),
            ],
          ),
          const SizedBox(height: 24),
          _buildDataChannelsTable(state),
          const SizedBox(height: 32),
          _buildSectionLabel('STRAPPING POINTS'),
          const SizedBox(height: 16),
          _buildDetailsStrappingTable(state.tank),
        ],
      ),
    );
  }

  Widget _buildDetailsStrappingTable(Tank? tank) {
    final points = tank?.strappingPoints ?? [];
    if (points.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(child: Text('No strapping points defined')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A), // Restored original navy
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'LEVEL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'VOLUME',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: points.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final point = points[index];
                  final bool isEven = index % 2 == 0;
                  final String levelVal = _getDisplayValue(point.levelMm, point.levelUnit ?? _selectedLevelUnit);
                  final String levelUnit = point.levelUnit ?? _selectedLevelUnit;
                  final String volumeVal = _getDisplayValue(point.volumeM3, point.volumeUnit ?? _selectedVolumeUnit);
                  final String volumeUnit = point.volumeUnit ?? _selectedVolumeUnit;

                  return Container(
                    color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: levelVal,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                TextSpan(
                                  text: ' $levelUnit',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: volumeVal,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                TextSpan(
                                  text: ' $volumeUnit',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
  }

  Widget _buildChartCard(TankDetailsState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level (%)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              Row(
                children: [
                  _buildChartLegendItem('Level', const Color(0xFF141E7A)),
                  const SizedBox(width: 16),
                  _buildChartLegendItem('Forecast', const Color(0xFF9CA3AF), dotted: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16.0),
              child: TankLevelChart(data: state.chartData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color, {bool dotted = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildDataChannelsTable(TankDetailsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data Channels',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            AppTableFilterPopup(
              options: const ['Normal', 'Critical', 'Warning'],
              selectedOptions: const [],
              onApply: (selected) {
                // TODO: Update state
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              ...state.dataChannels.map((channel) => _buildChannelRow(channel)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: const [
          Expanded(child: Text('Channel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Value', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Trend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildChannelRow(DataChannel channel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(channel.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(channel.currentReading, style: GoogleFonts.inter(fontSize: 13))),
          Expanded(
            child: Text(
              channel.status,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: channel.status == 'Normal' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ),
          Expanded(
            child: Icon(
              channel.trend == 'Up' ? Icons.trending_up : Icons.trending_down,
              color: channel.trend == 'Up' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(TankDetailsState state) {
    if (state.events.isEmpty) return const Center(child: Text('No events recorded.'));

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.events.length,
      itemBuilder: (context, index) {
        final event = state.events[index];
        final color = event.type == 'Critical' ? const Color(0xFFEF4444) : (event.type == 'Warning' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6));
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF111827)),
                        ),
                        Text(
                          DateFormat('HH:mm').format(event.timestamp),
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadingsTab(TankDetailsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricCard(
                  label: 'Current Level',
                  value: '65%',
                  icon: Icons.water_drop,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppMetricCard(
                  label: 'Current Pressure',
                  value: '120 Psi',
                  icon: Icons.speed,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historical Readings',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              AppTableFilterPopup(
                options: const ['Level', 'Pressure', 'Temperature'],
                selectedOptions: const [],
                onApply: (selected) {
                  // TODO: Update state
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildHistoryHeader(),
                ...state.readings.map((r) => _buildHistoryRow(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF141E7A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: const [
          Expanded(child: Text('Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Parameter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          Expanded(child: Text('Value', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(TankReading reading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        children: [
          Expanded(child: Text(DateFormat('yyyy-MM-dd HH:mm').format(reading.timestamp), style: const TextStyle(fontSize: 13))),
          Expanded(child: Text(reading.parameter, style: const TextStyle(fontSize: 13))),
          Expanded(child: Text('${reading.value} ${reading.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildForecastTab(TankDetailsState state) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: state.forecasts.length,
      itemBuilder: (context, index) {
        final f = state.forecasts[index];
        return Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next Refill Prediction', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Predicted Date', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM dd, yyyy').format(f.timestamp), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confidence', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                      const SizedBox(height: 4),
                      Text('${(f.confidence * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapTab(TankDetailsState state, Tank? tank) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Color(0xFF9CA3AF)),
            SizedBox(height: 16),
            Text('Map Integration Placeholder', style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationTab(TankDetailsState state, Tank? tank) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Configuration Card
          Expanded(
            flex: 1,
            child: _buildSectionCard(
              icon: Icons.settings_input_component_outlined,
              title: 'Tank Configuration',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField('Description', tank?.description ?? '—'),
                  const SizedBox(height: 20),
                  _buildReadOnlyField('Type *', tank?.tankTypeName ?? '—'),
                  const SizedBox(height: 24),
                  _buildDimensionGrid(tank?.tankTypeName, tank),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Technical Illustration',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TankDiagramWidget(
                          tankType: tank?.tankTypeName ?? '',
                          width: double.infinity,
                          height: 400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Right Panel: Stripping Points Card
          Expanded(
            flex: 1,
            child: _buildSectionCard(
              icon: Icons.layers_outlined,
              title: 'Strapping Points',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSectionLabel('GENERATE POINTS'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _generateCountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _generatePoints,
                          icon: const Icon(Icons.flash_on, size: 16),
                          label: const Text('GENERATE'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF141E7A),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStrippingPointsTable(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _saveInformation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141E7A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: state.isLoading
                          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('SAVE CONFIGURATION', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF141E7A)),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildDimensionGrid(String? type, Tank? tank) {
    if (type == null || tank == null) return const SizedBox.shrink();
    
    final List<Widget> fields = [];
    final t = type.trim();

    // Helper for adding read-only fields with unit
    void addDim(String label, double? value) {
      fields.add(_buildReadOnlyField(label, value != null ? '${value.toString()} mm' : '—'));
    }

    if (t == 'Horizontal with 2:1 Ellipsoidal Ends' ||
        t == 'Horizontal with Hemispherical Ends' ||
        t == 'Vertical with 2:1 Ellipsoidal Ends' ||
        t == 'Vertical with Flat Ends' ||
        t == 'Vertical with Hemispherical Ends' ||
        t == 'Spherical' ||
        t == 'None') {
      addDim('Can Length (L)', tank.canLength);
      addDim('Diameter (D)', tank.diameter);
    } else if (t == 'Horizontal with Flat Ends') {
      addDim('Length (L)', tank.length);
      addDim('Diameter (D)', tank.diameter);
    } else if (t == 'Horizontal with Variable Dished Ends' || t == 'Vertical with Variable Dished Ends') {
      addDim('Can Length (L)', tank.canLength);
      addDim('Diameter (D)', tank.diameter);
      addDim('Dish Depth (DL)', tank.dishDepth);
    } else if (t == 'Rectangular') {
      addDim('Height (H)', tank.height);
      addDim('Width (W)', tank.width);
      addDim('Depth (D)', tank.depth);
    } else if (t == 'Vertical with Conical Bottom End') {
      addDim('Can Length (L)', tank.canLength);
      addDim('Diameter (D)', tank.diameter);
      addDim('Cone Length (CL)', tank.coneLength);
    } else {
      addDim('Height (H)', tank.height);
      addDim('Diameter (D)', tank.diameter);
    }

    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('TECHNICAL DIMENSIONS'),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: fields,
        ),
      ],
    );
  }


  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label.toUpperCase()),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(color: const Color(0xFF111827), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _getDisplayValue(double baseVal, String unit, {bool isVolumeColumn = false}) {
    // Return raw value as per user request to maintain 'as-is' entry
    if (baseVal == baseVal.toInt()) return baseVal.toInt().toString();
    return baseVal.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }


  Widget _buildUnitDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        Text(
          '$label (',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
        ),
        Theme(
          data: ThemeData(
            canvasColor: const Color(0xFF1E293B),
            textTheme: TextTheme(
              titleMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 14),
            isDense: true,
            dropdownColor: const Color(0xFF1E293B),
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
            items: options.map((String opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: onChanged,
          ),
        ),
        Text(
          ')',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStrippingPointsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF141E7A), // Restored original navy
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11), 
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _buildUnitDropdown('LEVEL', _selectedLevelUnit, _unitOptions, (val) => setState(() => _selectedLevelUnit = val!))),
                const SizedBox(width: 40),
                Expanded(child: _buildUnitDropdown('VOLUME', _selectedVolumeUnit, _unitOptions, (val) => setState(() => _selectedVolumeUnit = val!))),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _editPoints.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final bool isEven = index % 2 == 0;
                return Container(
                  color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('level-$index-$_selectedLevelUnit-$_saveVersion'),
                          initialValue: _editPoints[index].levelMm == 0 ? '' : _getDisplayValue(_editPoints[index].levelMm, _selectedLevelUnit),
                          decoration: InputDecoration(
                            border: InputBorder.none, 
                            hintText: '0.00 $_selectedLevelUnit',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w400),
                          ),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          onChanged: (val) {
                            final double? v = double.tryParse(val);
                            if (v != null) {
                              setState(() {
                                _editPoints[index] = StrappingPoint(
                                  levelMm: v,
                                  volumeM3: _editPoints[index].volumeM3,
                                  levelUnit: _selectedLevelUnit,
                                  volumeUnit: _editPoints[index].volumeUnit ?? _selectedVolumeUnit,
                                );
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('volume-$index-$_selectedVolumeUnit-$_saveVersion'),
                          initialValue: _editPoints[index].volumeM3 == 0 ? '' : _getDisplayValue(_editPoints[index].volumeM3, _selectedVolumeUnit, isVolumeColumn: true),
                          decoration: InputDecoration(
                            border: InputBorder.none, 
                            hintText: '0.00 $_selectedVolumeUnit',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w400),
                          ),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xFF1E293B)),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          onChanged: (val) {
                            final double? v = double.tryParse(val);
                            if (v != null) {
                              setState(() {
                                _editPoints[index] = StrappingPoint(
                                  levelMm: _editPoints[index].levelMm,
                                  volumeM3: v,
                                  levelUnit: _editPoints[index].levelUnit ?? _selectedLevelUnit,
                                  volumeUnit: _selectedVolumeUnit,
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  void _generatePoints() {
    final int? count = int.tryParse(_generateCountController.text);
    if (count != null && count > 0) {
      setState(() {
        _editPoints = List.generate(count, (_) => StrappingPoint(levelMm: 0, volumeM3: 0));
      });
    }
  }

  Future<void> _saveInformation() async {
    final state = ref.read(tankDetailsProvider);
    final tank = state.tank ?? widget.tank;
    
    if (tank == null) return;

    final messenger = ScaffoldMessenger.of(context);
    
    final request = TankCreateRequest(
      tankNumber: tank.tankNumber,
      tankTypeId: tank.tankTypeId,
      unitId: tank.unitId,
      productId: tank.productId,
      plantId: tank.plantId,
      status: tank.status,
      description: tank.description, // Use existing as it's now read-only
      useStrappingChart: _useStrappingChart,
      strappingPoints: _editPoints.where((p) => p.levelMm > 0 || p.volumeM3 > 0).map((p) => StrappingPoint(
        levelMm: p.levelMm,
        volumeM3: p.volumeM3,
        levelUnit: _selectedLevelUnit,
        volumeUnit: _selectedVolumeUnit,
      )).toList(),
      width: tank.width,
      height: tank.height,
      dishHeight: tank.dishHeight,
      canLength: tank.canLength,
      diameter: tank.diameter,
      length: tank.length,
      dishDepth: tank.dishDepth,
      depth: tank.depth,
      coneLength: tank.coneLength,
      tonnes: tank.tonnes,
      levelUnit: _selectedLevelUnit,
      volumeUnit: _selectedVolumeUnit,
    );

    final success = await ref.read(tankProvider.notifier).updateTank(tank.tankId, request);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Information updated successfully')),
      );
      
      // Clear input list and controller for new record entry as requested
      setState(() {
        _editPoints = [StrappingPoint(levelMm: 0, volumeM3: 0)];
        _generateCountController.clear();
        _saveVersion++; // Force complete reset of all text fields
      });

      // Reload details data
      ref.read(tankDetailsProvider.notifier).loadData(tank.tankId);
    } else {
      final error = ref.read(tankProvider).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${error ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
