import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository_impl.dart';
import '../presentation/model/tank_data_model.dart';

abstract class DashboardRepository {
  Future<List<TankDataModel>> getTankStatus();
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref);
});
