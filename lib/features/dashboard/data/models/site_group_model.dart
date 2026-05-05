
import 'tank_data_model.dart';

class SiteGroupModel {
  final String siteName;
  final String city;
  final List<TankDataModel> tanks;

  SiteGroupModel({
    required this.siteName,
    required this.city,
    required this.tanks,
  });
}