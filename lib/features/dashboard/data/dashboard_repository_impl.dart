import 'package:air_water/features/dashboard/data/tank_data_model.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_api.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardApi _api;

  DashboardRepositoryImpl(this._api);

  @override
  Future<List<TankDataModel>> getTankData() async {

    try {
      final list = await _api.getTankData();
      return list.map((e) => TankDataModel.fromJson(e)).toList();

    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : null;

      if (status == 404) {
        throw AppException(message ?? 'Products not found');
      }

      throw AppException(message ?? 'Failed to load products');
    }
  }
}