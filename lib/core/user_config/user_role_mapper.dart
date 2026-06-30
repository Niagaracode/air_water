import 'user_role.dart';

UserRole mapUserRole(String role) {
  switch (role.toUpperCase()) {
    case 'SUPER_ADMIN':
      return UserRole.superAdmin;

    case 'ADMIN':
      return UserRole.companyAdmin;

    case 'END CUSTOMER':
      return UserRole.customer;

    default:
      throw Exception('Unknown role: $role');
  }
}
