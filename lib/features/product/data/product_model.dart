class Product {
  final int id;
  final String name;
  final String productCode;
  final String description;
  final double scmM3;
  final double specificGravity;

  const Product({
    required this.id,
    required this.name,
    required this.productCode,
    required this.description,
    required this.scmM3,
    required this.specificGravity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] ?? json['id'] ?? 0,
      name: json['product_name']?.toString() ?? '',
      productCode: json['product_code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      scmM3:
      double.tryParse(json['scm_m3']?.toString() ?? '0') ?? 0.0,
      specificGravity:
      double.tryParse(json['specificgravity']?.toString() ?? '0') ??
          0.0,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? productCode,
    String? description,
    double? scmM3,
    double? specificGravity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      productCode: productCode ?? this.productCode,
      description: description ?? this.description,
      scmM3: scmM3 ?? this.scmM3,
      specificGravity:
      specificGravity ?? this.specificGravity,
    );
  }
}