class Alarm {
  final int id;
  final String ruleName;
  final String plantName;
  final String tankNumber;
  final String parameterType;
  final String conditionType;
  final double threshold1;
  final double? threshold2;
  final double currentValue;
  final String importance; // High, Medium, Low
  final DateTime triggeredAt;
  final String status; // Active, Resolved

  Alarm({
    required this.id,
    required this.ruleName,
    required this.plantName,
    required this.tankNumber,
    required this.parameterType,
    required this.conditionType,
    required this.threshold1,
    this.threshold2,
    required this.currentValue,
    required this.importance,
    required this.triggeredAt,
    this.status = 'Active',
  });

  factory Alarm.mock({
    required int id,
    required String ruleName,
    required String plantName,
    required String tankNumber,
    required String parameterType,
    required String conditionType,
    required double threshold1,
    double? threshold2,
    required double currentValue,
    required String importance,
  }) {
    return Alarm(
      id: id,
      ruleName: ruleName,
      plantName: plantName,
      tankNumber: tankNumber,
      parameterType: parameterType,
      conditionType: conditionType,
      threshold1: threshold1,
      threshold2: threshold2,
      currentValue: currentValue,
      importance: importance,
      triggeredAt: DateTime.now().subtract(Duration(minutes: id * 15)),
    );
  }
}
