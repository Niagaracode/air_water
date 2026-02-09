import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import 'user_role.dart';
import 'user_role_mapper.dart';

final userRoleProvider = FutureProvider<UserRole>((ref) async {
  final storage = ref.read(secureStorageProvider);

  final roleStr = await storage.readRole();

  if (roleStr == null) {
    throw Exception('User role not found');
  }

  return mapUserRole(roleStr);
});