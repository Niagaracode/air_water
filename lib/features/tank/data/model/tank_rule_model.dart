class TankRuleModel {
  final int id;
  final String ruleName;

  TankRuleModel({
    required this.id,
    required this.ruleName,
  });

  factory TankRuleModel.fromJson(Map<String, dynamic> json) {
    return TankRuleModel(
      id: json['id'] ?? 0,
      ruleName: json['name']?.toString() ?? '',
    );
  }
}