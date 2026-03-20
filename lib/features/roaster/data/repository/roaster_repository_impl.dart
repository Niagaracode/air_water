import '../../domain/repository/roaster_repository.dart';
import '../api/roaster_api.dart';
import '../../presentation/model/roaster_model.dart';

class RoasterRepositoryImpl implements RoasterRepository {
  final RosterApi _api;
  RoasterRepositoryImpl(this._api);

  @override
  Future<RosterResponse> getRoasters({int page = 1, int limit = 10, String? search}) {
    return _api.getRosters(page: page, limit: limit, search: search);
  }

  @override
  Future<void> createRoaster(Map<String, dynamic> data) {
    return _api.createRoster(data);
  }

  @override
  Future<void> updateRoster(int id, Map<String, dynamic> data) {
    return _api.updateRoster(id, data);
  }

  @override
  Future<void> deleteRoaster(int id) {
    return _api.deleteRoster(id);
  }

  @override
  Future<void> addMember(Map<String, dynamic> data) {
    return _api.addMember(data);
  }

  @override
  Future<void> updateMember(int memberId, Map<String, dynamic> data) {
    return _api.updateMember(memberId, data);
  }

  @override
  Future<void> removeMember(int memberId) {
    return _api.removeMember(memberId);
  }

  @override
  Future<void> manageAssignments(int roasterId, List<dynamic> assignments) {
    // Legacy support if needed
    return Future.value();
  }

  @override
  Future<Roster> getRosterById(int id) async {
    final data = await _api.getRosterById(id);
    return Roster.fromJson(data);
  }

  @override
  Future<List<RosterMember>> getRosterMembers(int rosterId) {
    return _api.getRosterMembers(rosterId);
  }
}
