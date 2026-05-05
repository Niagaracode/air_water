import '../domain/dashboard_repository.dart';
import 'dashboard_api.dart';
import 'models/tank_data_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardApi _api;

  DashboardRepositoryImpl(this._api);

  @override
  Future<List<TankDataModel>> getTankData() async {
    final list = await _api.getTankData();
    return list.map((e) => TankDataModel.fromJson(e)).toList();
  }
}