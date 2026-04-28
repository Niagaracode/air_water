import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/dashboard_repository.dart';
import '../presentation/model/tank_data_model.dart';
import 'dashboard_api.dart';
import '../../../core/network/api_client.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final Ref _ref;

  DashboardRepositoryImpl(this._ref);

  @override
  Future<List<TankDataModel>> getTankStatus() async {
    final client = _ref.read(apiClientProvider);
    final api = DashboardApi(client);
    return await api.getTankStatus();
  }
}
