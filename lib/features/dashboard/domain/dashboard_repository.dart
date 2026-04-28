import 'package:air_water/features/dashboard/data/tank_data_model.dart';

abstract class DashboardRepository {
  Future<List<TankDataModel>> getTankData();
}