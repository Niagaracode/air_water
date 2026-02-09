import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/api/auth_api.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/usecase/login_usecase.dart';
import 'auth_controller.dart';

final authApiProvider =
Provider((ref) => AuthApi(ref.read(apiClientProvider)));

final authRepositoryProvider = Provider((ref) => AuthRepositoryImpl(
  ref.read(authApiProvider), ref.read(secureStorageProvider),
));

final loginUseCaseProvider = Provider((ref) => LoginUseCase(
    ref.read(authRepositoryProvider)));

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
