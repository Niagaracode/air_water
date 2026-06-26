import 'tank_dimension_model.dart';

abstract class TankDimensionRepository {
  Future<List<TankDimension>> getTankDimensions();
  Future<TankDimension> createTankDimension(Map<String, dynamic> data);
  Future<TankDimension> updateTankDimension(int id, Map<String, dynamic> data);
  Future<void> deleteTankDimension(int id);
}
