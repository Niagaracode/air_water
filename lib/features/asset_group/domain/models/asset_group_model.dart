import 'dart:convert';

class AssetGroupModel {
  final int? id;
  final String name;
  final String description;
  final bool displayInTree;
  final String domain;
  final List<AssetCriteria> criteria;
  final int? userCount;
  final List<AssetGroupUser>? users;

  AssetGroupModel({
    this.id,
    required this.name,
    required this.description,
    this.displayInTree = true,
    this.domain = 'AIRWATER',
    required this.criteria,
    this.userCount,
    this.users,
  });

  factory AssetGroupModel.fromJson(Map<String, dynamic> json) {
    List<AssetCriteria> parsedCriteria = [];
    if (json['criteria'] != null && json['criteria'] is List) {
      parsedCriteria = (json['criteria'] as List).map((c) => AssetCriteria.fromJson(c)).toList();
    } else if (json['criteria_json'] != null) {
      // Fallback for legacy data if needed during transition
      final dynamic decoded = json['criteria_json'] is String 
          ? jsonDecode(json['criteria_json']) 
          : json['criteria_json'];
      if (decoded is List) {
        parsedCriteria = decoded.map((c) => AssetCriteria.fromJson(c)).toList();
      }
    }

    return AssetGroupModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      displayInTree: json['display_in_tree'] == 1,
      domain: json['domain'] ?? 'AIRWATER',
      criteria: parsedCriteria,
      userCount: json['user_count'],
      users: json['users'] != null 
          ? (json['users'] as List).map((u) => AssetGroupUser.fromJson(u)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'display_in_tree': displayInTree ? 1 : 0,
      'criteria': criteria.map((c) => c.toJson()).toList(),
      'users': users?.map((u) => u.toJson()).toList(),
    };
  }
}

class AssetCriteria {
  String parameter;
  String logic;
  String value;
  String operator;

  AssetCriteria({
    required this.parameter,
    required this.logic,
    required this.value,
    this.operator = 'And',
  });

  factory AssetCriteria.fromJson(Map<String, dynamic> json) {
    return AssetCriteria(
      parameter: json['parameter'] ?? '',
      logic: json['logic'] ?? '=',
      value: json['value'] ?? '',
      operator: json['operator'] ?? 'And',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter': parameter,
      'logic': logic,
      'value': value,
      'operator': operator,
    };
  }
}

class AssetGroupUser {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? roleName;
  bool defaultSecurity;
  bool isDefault;

  AssetGroupUser({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.roleName,
    this.defaultSecurity = false,
    this.isDefault = false,
  });

  factory AssetGroupUser.fromJson(Map<String, dynamic> json) {
    return AssetGroupUser(
      userId: json['user_id'],
      username: json['username'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      roleName: json['role_name'],
      defaultSecurity: json['default_security'] == 1,
      isDefault: json['is_default'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'default_security': defaultSecurity ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
    };
  }
}
