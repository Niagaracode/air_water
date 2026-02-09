import 'user_role.dart';

UserRole mapUserRole(String role) {
  switch (role.toUpperCase()) {
    case 'SUPER_ADMIN':
      return UserRole.superAdmin;

    case 'COMPANY_ADMIN':
      return UserRole.companyAdmin;

    case 'DISTRIBUTOR':
      return UserRole.distributor;

    case 'SUPERVISOR':
      return UserRole.supervisor;

    case 'TECHNICIAN':
      return UserRole.technician;

    case 'CUSTOMER':
      return UserRole.customer;

    case 'IOT_MANAGER':
      return UserRole.iotManager;

    default:
      throw Exception('Unknown role: $role');
  }
}