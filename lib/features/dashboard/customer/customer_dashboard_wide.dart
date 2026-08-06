import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/user_config/user_role.dart';
import '../../tank/presentation/view/tank_details_view.dart';
import '../data/models/tank_data_model.dart';
import '../provider/dashboard_controller.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/build_empty_tank_view.dart';
import '../widgets/build_loading_view.dart';
import '../widgets/dashboard_list_view.dart';

class CustomerDashboardWide extends ConsumerStatefulWidget {
  const CustomerDashboardWide({super.key});

  @override
  ConsumerState<CustomerDashboardWide> createState() => _CustomerDashboardWideState();
}

class _CustomerDashboardWideState extends ConsumerState<CustomerDashboardWide> {
  final String _selectedStatus = 'All Status';
  final String _selectedRegion = 'All Regions';
  TankDataModel? _selectedTank;

  @override
  Widget build(BuildContext context) {

    final tanksAsync = ref.watch(tankDataProvider);
    final groupedTanks = ref.watch(groupedTanksProvider);

    return Container(
      child: tanksAsync.when(
        loading: () => buildLoadingView(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (tanks) {
          // If no tank is selected and tanks exist, select the first one
          if (_selectedTank == null && tanks.isNotEmpty) {
            _selectedTank = tanks.first;
          }

          return Row(
            children: [
              // Left Panel - Tank List
              SizedBox(
                width: 370,
                child: DashboardListView(
                  groupedTanks: groupedTanks,
                  filteredTanks: tanks,
                  selectedRegion: _selectedRegion,
                  selectedStatus: _selectedStatus,
                  searchQuery: '',
                  onTankTap: (tank) {
                    setState(() {
                      _selectedTank = tank;
                    });
                  },
                  userRole: UserRole.customer,
                ),
              ),
              VerticalDivider(width : 5, color: Colors.black12),
              // Right Panel - Tank Details
              Expanded(
                child: _selectedTank != null
                    ? TankDetailsView(tankId: _selectedTank!.id, tank: _selectedTank!, isNarrow: false,)
                    : buildEmptyDetailView(),
              ),
            ],
          );
        },
      ),
    );
  }
}