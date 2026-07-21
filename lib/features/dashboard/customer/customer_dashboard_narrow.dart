import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/user_config/user_role.dart';
import '../../tank/presentation/view/tank_details_view.dart';
import '../provider/dashboard_controller.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/build_empty_tank_view.dart';
import '../widgets/build_loading_view.dart';
import '../widgets/dashboard_list_view.dart';

class CustomerDashboardNarrow extends ConsumerStatefulWidget {
  const CustomerDashboardNarrow({
    super.key,
  });

  @override
  ConsumerState<CustomerDashboardNarrow> createState() => _CustomerDashboardNarrowState();
}

class _CustomerDashboardNarrowState extends ConsumerState<CustomerDashboardNarrow> {
  final String _selectedStatus = 'All Status';
  final String _selectedRegion = 'All Regions';

  @override
  Widget build(BuildContext context) {
    ref.watch(dashboardControllerProvider);
    final tanksAsync = ref.watch(tankDataProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: tanksAsync.when(
        loading: () => buildLoadingView(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (tanks) {
          if (tanks.isEmpty) {
            return buildEmptyTanksView();
          }
          return DashboardListView(
            groupedTanks: groupedTanks,
            filteredTanks: tanks,
            selectedRegion: _selectedRegion,
            selectedStatus: _selectedStatus,
            searchQuery: '',
            isNarrow: true,
            onTankTap: (tank) {
              // Navigate to details page when tank is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TankDetailsView(
                    tankId: tank.id,
                    tank: tank,
                    isNarrow: true,
                  ),
                ),
              );
            },
            userRole: UserRole.customer,
          );
        },
      ),
    );
  }

}