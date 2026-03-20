import '../../presentation/model/roaster_model.dart';

abstract class RoasterRepository {
  Future<RosterResponse> getRoasters({int page = 1, int limit = 10, String? search});
  Future<void> createRoaster(Map<String, dynamic> data);
  Future<void> updateRoster(int id, Map<String, dynamic> data);
  Future<void> deleteRoaster(int id);
  
  // Member Management
  Future<void> addMember(Map<String, dynamic> data);
  Future<void> updateMember(int memberId, Map<String, dynamic> data);
  Future<void> removeMember(int memberId);

  Future<Roster> getRosterById(int id);
  Future<List<RosterMember>> getRosterMembers(int rosterId);

  // Legacy
  Future<void> manageAssignments(int roasterId, List<dynamic> assignments);
}
