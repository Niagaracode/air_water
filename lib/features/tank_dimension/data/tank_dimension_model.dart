class TankDimension {
  final int id;
  final String name;
  final String type;
  final String unitOfMeasures;
  final double canLength;
  final double diameter;
  final double dishDepth;
  final double maxOverflow;
  final String description;

  const TankDimension({
    required this.id,
    this.name = '',
    required this.type,
    this.unitOfMeasures = '',
    this.canLength = 0.0,
    this.diameter = 0.0,
    this.dishDepth = 0.0,
    required this.maxOverflow,
    this.description = '',
  });

  factory TankDimension.fromJson(Map<String, dynamic> json) {
    return TankDimension(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      unitOfMeasures: json['unit_of_measures']?.toString() ?? '',
      canLength: double.tryParse(json['can_length']?.toString() ?? '0') ?? 0.0,
      diameter: double.tryParse(json['diameter']?.toString() ?? '0') ?? 0.0,
      dishDepth: double.tryParse(json['dish_depth']?.toString() ?? '0') ?? 0.0,
      maxOverflow: double.tryParse(json['max_overflow']?.toString() ?? '0') ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }

  TankDimension copyWith({
    int? id,
    String? name,
    String? type,
    String? unitOfMeasures,
    double? canLength,
    double? diameter,
    double? dishDepth,
    double? maxOverflow,
    String? description,
  }) {
    return TankDimension(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unitOfMeasures: unitOfMeasures ?? this.unitOfMeasures,
      canLength: canLength ?? this.canLength,
      diameter: diameter ?? this.diameter,
      dishDepth: dishDepth ?? this.dishDepth,
      maxOverflow: maxOverflow ?? this.maxOverflow,
      description: description ?? this.description,
    );
  }
}
