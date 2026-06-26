class TankDimension {
  final int id;
  final String type;
  final String unitOfMeasures;
  final double canLength;
  final double diameter;
  final double dishDepth;
  final String description;

  const TankDimension({
    required this.id,
    required this.type,
    required this.unitOfMeasures,
    required this.canLength,
    required this.diameter,
    required this.dishDepth,
    required this.description,
  });

  factory TankDimension.fromJson(Map<String, dynamic> json) {
    return TankDimension(
      id: json['id'] ?? 0,
      type: json['type']?.toString() ?? '',
      unitOfMeasures: json['unit_of_measures']?.toString() ?? '',
      canLength: double.tryParse(json['can_length']?.toString() ?? '0') ?? 0.0,
      diameter: double.tryParse(json['diameter']?.toString() ?? '0') ?? 0.0,
      dishDepth: double.tryParse(json['dish_depth']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }

  TankDimension copyWith({
    int? id,
    String? type,
    String? unitOfMeasures,
    double? canLength,
    double? diameter,
    double? dishDepth,
    String? description,
  }) {
    return TankDimension(
      id: id ?? this.id,
      type: type ?? this.type,
      unitOfMeasures: unitOfMeasures ?? this.unitOfMeasures,
      canLength: canLength ?? this.canLength,
      diameter: diameter ?? this.diameter,
      dishDepth: dishDepth ?? this.dishDepth,
      description: description ?? this.description,
    );
  }
}
