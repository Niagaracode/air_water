class Product {
  final int id;
  final String name;
  final String productCode;
  final String description;
  final double scmM3;
  final double specificGravity;

  Product({
    required this.id,
    required this.name,
    required this.productCode,
    required this.description,
    required this.scmM3,
    required this.specificGravity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    print('PRODUCT JSON → $json'); // keep for debug

    return Product(
      id: json['product_id'] ?? 0,

      // ✅ SAFE string parsing
      name: json['product_name']?.toString() ?? '',

      productCode: json['product_code']?.toString() ?? '',

      description: json['description']?.toString() ?? '',

      // ✅ SAFE number parsing
      scmM3: double.tryParse(json['scm_m3']?.toString() ?? '') ?? 0.0,

      specificGravity:
      double.tryParse(json['specificgravity']?.toString() ?? '') ?? 0.0,
    );
  }
}