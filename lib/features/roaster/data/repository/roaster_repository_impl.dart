import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';
import 'package:air_water/features/roaster/domain/repository/roaster_repository.dart';
import 'package:air_water/features/roaster/data/api/roaster_api.dart';

class RoasterRepositoryImpl implements RoasterRepository {
  final RosterApi _api;

  RoasterRepositoryImpl(this._api);

  @override
  Future<RoasterResponse> getRoasters({
    int page = 1,
    int limit = 10,
    String? name,
    int? plantId,
  }) async {
    return await _api.getRoasters(page: page, limit: limit, name: name, plantId: plantId);
  }

  @override
  Future<RoasterWithAssignments> getRoasterById(int id) async {
    return await _api.getRoasterById(id);
  }

  @override
  Future<void> createRoaster(Map<String, dynamic> data) async {
    await _api.createRoaster(data);
  }

  @override
  Future<void> updateRoaster(int id, Map<String, dynamic> data) async {
    await _api.updateRoaster(id, data);
  }

  @override
  Future<void> deleteRoaster(int id) async {
    await _api.deleteRoaster(id);
  }

  @override
  Future<void> manageAssignments({
    required int roasterId,
    required List<Map<String, dynamic>> assignments,
  }) async {
    await _api.assignParameters(
      roasterId: roasterId,
      assignments: assignments,
    );
  }
}
