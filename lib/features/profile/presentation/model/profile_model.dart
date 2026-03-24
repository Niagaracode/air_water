class ProfileModel {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobileNumber;
  final int? roleId;
  final String? roleName;
  final int? companyId;
  final String? companyName;
  final List<AddressModel> addresses;

  ProfileModel({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.mobileNumber,
    this.roleId,
    this.roleName,
    this.companyId,
    this.companyName,
    this.addresses = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      roleId: json['role_id'] as int?,
      roleName: json['role_name'] as String?,
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      addresses: (json['addresses'] as List? ?? [])
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ProfileModel copyWith({
    String? username,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    String? companyName,
    List<AddressModel>? addresses,
  }) {
    return ProfileModel(
      userId: userId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      roleId: roleId,
      roleName: roleName,
      companyId: companyId,
      companyName: companyName ?? this.companyName,
      addresses: addresses ?? this.addresses,
    );
  }
}

class AddressModel {
  final int? id;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? pincode;
  final String? city;
  final String? state;
  final String? country;

  AddressModel({
    this.id,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.pincode,
    this.city,
    this.state,
    this.country,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as int?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      addressLine3: json['address_line_3'] as String?,
      pincode: json['pincode'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'address_line_3': addressLine3,
      'pincode': pincode,
      'city': city,
      'state': state,
      'country': country,
    };
  }

  AddressModel copyWith({
    int? id,
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? pincode,
    String? city,
    String? state,
    String? country,
  }) {
    return AddressModel(
      id: id ?? this.id,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      addressLine3: addressLine3 ?? this.addressLine3,
      pincode: pincode ?? this.pincode,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }
}

class ProfileUpdateRequest {
  final String? username;
  final String? password;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobileNumber;
  final String? companyName;
  final List<AddressModel>? addresses;

  ProfileUpdateRequest({
    this.username,
    this.password,
    this.firstName,
    this.lastName,
    this.email,
    this.mobileNumber,
    this.companyName,
    this.addresses,
  });

  Map<String, dynamic> toJson() {
    return {
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (companyName != null) 'company_name': companyName,
      if (addresses != null) 'addresses': addresses!.map((e) => e.toJson()).toList(),
    };
  }
}
