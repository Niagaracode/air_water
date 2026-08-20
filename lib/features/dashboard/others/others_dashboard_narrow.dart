import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme/app_theme.dart';
import '../../../core/user_config/user_role.dart';
import '../../tank/presentation/view/tank_details_view.dart';
import '../data/models/tank_data_model.dart';
import '../provider/dashboard_provider.dart';
import '../provider/dashboard_filter_provider.dart';
import '../utils/tank_report_exporter.dart';
import '../widgets/build_loading_view.dart';
import '../widgets/dashboard_list_view.dart';
import '../widgets/dashboard_map_view.dart';
import '../widgets/search_and_filters.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/view_toggle.dart';

class OthersDashboardNarrow extends ConsumerWidget {
  const OthersDashboardNarrow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tanksAsync = ref.watch(tankDataProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);
    final statistics = ref.watch(tankStatisticsProvider);

    final filters = ref.watch(dashboardFilterProvider);
    final filterNotifier = ref.read(dashboardFilterProvider.notifier);

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
                  onSearchChanged: filterNotifier.setSearch,
                  onRegionChanged: filterNotifier.setRegion,
                  onStatusChanged: filterNotifier.setStatus,
                  onProductChanged: filterNotifier.setProduct,
                  onClearFilters: filterNotifier.clearFilters,
                  selectedRegion: filters.selectedRegion,
                  selectedStatus: filters.selectedStatus,
                  selectedProduct: filters.selectedProduct,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ViewToggle(
                      currentView:
                      filters.isListView ? ViewType.list : ViewType.map,
                      onViewChanged: (val) =>
                          filterNotifier.setView(val == ViewType.list),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Download Report',
                      onSelected: (value) async {
                        final allTanks = ref.read(tankDataProvider).value ?? [];
                        await TankReportExporter.export(
                          format: value,
                          allTanks: allTanks,
                          selectedStatus: filters.selectedStatus,
                          selectedRegion: filters.selectedRegion,
                          selectedProduct: filters.selectedProduct,
                          searchQuery: filters.searchQuery,
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
                filters.isListView
                    ? DashboardListView(
                  groupedTanks: groupedTanks,
                  filteredTanks: tanks,
                  selectedRegion: filters.selectedRegion,
                  selectedStatus: filters.selectedStatus,
                  selectedProduct: filters.selectedProduct,
                  searchQuery: filters.searchQuery,
                  userRole: UserRole.superAdmin,
                  onTankTap: (tank) => _callDetailsPage(context, tank),
                  isNarrow: true,
                )
                    : DashboardMapView(tanksData: tanks),
              ],
            ),
          );
        },
      ),
    );
  }

  void _callDetailsPage(BuildContext context, TankDataModel tank) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TankDetailsView(tankId: tank.id, tank: tank, isNarrow: true),
      ),
    );
  }
}