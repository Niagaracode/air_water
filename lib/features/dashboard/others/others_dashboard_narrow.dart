import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme/app_theme.dart';
import '../../../core/user_config/user_role.dart';
import '../../tank/presentation/view/tank_details_view.dart';
import '../data/models/tank_data_model.dart';
import '../provider/dashboard_controller.dart';
import '../provider/dashboard_provider.dart';
import '../utils/tank_report_exporter.dart';
import '../widgets/build_loading_view.dart';
import '../widgets/dashboard_list_view.dart';
import '../widgets/dashboard_map_view.dart';
import '../widgets/search_and_filters.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/view_toggle.dart';

class OthersDashboardNarrow extends ConsumerStatefulWidget {
  const OthersDashboardNarrow({
    super.key,
  });

  @override
  ConsumerState<OthersDashboardNarrow> createState() => _OthersDashboardNarrowState();
}

class _OthersDashboardNarrowState extends ConsumerState<OthersDashboardNarrow> {

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All Status';
  String _selectedRegion = 'All Regions';
  String _selectedProduct = 'All Product';
  String _searchQuery = '';
  bool _isListView = true;

  @override
  Widget build(BuildContext context) {

    final tanksAsync = ref.watch(tankDataProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);
    final statistics = ref.watch(tankStatisticsProvider);

    return Container(
      color: Colors.white,

      child: tanksAsync.when(
        loading: () => buildLoadingView(),
        error: (error, _) => Center(
          child: Text(error.toString()),
        ),

        data: (tanks) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 12),
            child: Column(
              children: [
                StatisticsCards(statistics: statistics),
                const SizedBox(height: 20),
                SearchAndFilters(
                  isNarrow: true,
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

                  onProductChanged: (val) {
                    setState(() {
                      _selectedProduct = val;
                    });
                  },

                  onClearFilters: () {
                    setState(() {
                      _selectedRegion = 'All Regions';
                      _selectedStatus = 'All Status';
                      _selectedProduct = 'All Product';
                      _searchQuery = '';
                    });
                    _searchController.clear();
                  },

                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  selectedProduct: _selectedProduct,
                ),
                const SizedBox(height: 16),
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
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Download Report',
                      onSelected: (value) async {

                        final allTanks = ref.read(tankDataProvider).value ?? [];
                        await TankReportExporter.export(
                          format: value,
                          allTanks: allTanks,
                          selectedStatus: _selectedStatus,
                          selectedRegion: _selectedRegion,
                          selectedProduct: _selectedProduct,
                          searchQuery: _searchQuery,
                        );

                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'excel',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart_outlined, color: primary),
                              const SizedBox(width: 10),
                              const Text('Download Excel'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pdf',
                          child: Row(
                            children: [
                              Icon(Icons.picture_as_pdf_outlined, color: primary),
                              const SizedBox(width: 10),
                              const Text('Download PDF'),
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
                            const SizedBox(width: 8),
                            Text('Download', style: TextStyle(color: primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isListView ? DashboardListView(
                  groupedTanks: groupedTanks,
                  filteredTanks: tanks,
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  selectedProduct: _selectedProduct,
                  searchQuery: _searchQuery,
                  userRole: UserRole.superAdmin,
                  onTankTap: _callDetailsPage,
                  isNarrow: true,
                ) :
                DashboardMapView(tanksData: tanks),
              ],
            ),
          );
        },
      ),
    );

  }

  void _callDetailsPage(TankDataModel tank) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TankDetailsView(tankId: tank.id, tank: tank, isNarrow: true,),
      ),
    );
  }
}