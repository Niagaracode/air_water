import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/plant_repository.dart';
import 'plant_provider.dart';

final plantControllerProvider = Provider((ref) {
  final repository = ref.read(plantRepositoryProvider);
  return PlantController(repository, ref);
});

class PlantController {
  final PlantRepository _repository;
  final Ref _ref;

  PlantController(this._repository, this._ref);

  Future<void> refresh() async {
    await _ref.read(plantNotifierProvider.notifier).loadPlants();
  }
}
