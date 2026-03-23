import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() {
      ref.read(tankDetailsProvider.notifier).loadData(widget.tankId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tankDetailsProvider);
    final tankInfo = widget.tank;

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
            child: const Center(child: Text('Chart Placeholder')),
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
}
