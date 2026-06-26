import 'package:dio/dio.dart';
import '../../../core/errors/app_exception.dart';
import 'tank_dimension_api.dart';
import 'tank_dimension_model.dart';
import 'tank_dimension_repository.dart';

class TankDimensionRepositoryImpl implements TankDimensionRepository {
  final TankDimensionApi _api;
  TankDimensionRepositoryImpl(this._api);

  @override
  Future<List<TankDimension>> getTankDimensions() async {
    try {
      return await _api.getTankDimensions();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to load tank dimensions';
      throw AppException(message);
    }
  }

  @override
  Future<TankDimension> createTankDimension(Map<String, dynamic> data) async {
    try {
      return await _api.createTankDimension(data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to create tank dimension';
      throw AppException(message);
    }
  }

  @override
  Future<TankDimension> updateTankDimension(int id, Map<String, dynamic> data) async {
    try {
      return await _api.updateTankDimension(id, data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to update tank dimension';
      throw AppException(message);
    }
  }

  @override
  Future<void> deleteTankDimension(int id) async {
    try {
      await _api.deleteTankDimension(id);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Failed to delete tank dimension';
      throw AppException(message);
    }
  }
}
