
import '../../data/tank_data_model.dart';

class SiteGroupModel {
  final String siteName;
  final String siteLocation;
  final List<TankDataModel> tanks;

  SiteGroupModel({
    required this.siteName,
    required this.siteLocation,
    required this.tanks,
  });
}