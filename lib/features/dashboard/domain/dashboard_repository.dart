
import '../data/models/tank_data_model.dart';

abstract class DashboardRepository {
  Future<List<TankDataModel>> getTankData();

  Future<List<RegionModel>> getRegionList();
}