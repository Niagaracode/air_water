import 'package:air_water/features/roaster/presentation/model/roaster_model.dart';

abstract class RoasterRepository {
  Future<RoasterResponse> getRoasters({
    int page = 1,
    int limit = 10,
    String? name,
    int? plantId,
  });

  Future<RoasterWithAssignments> getRoasterById(int id);

  Future<void> createRoaster(Map<String, dynamic> data);

  Future<void> updateRoaster(int id, Map<String, dynamic> data);

  Future<void> deleteRoaster(int id);

  Future<void> manageAssignments({
    required int roasterId,
    required List<Map<String, dynamic>> assignments,
  });
}
