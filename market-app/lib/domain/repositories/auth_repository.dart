import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/models/auth_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponseModel>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  Future<AuthUserDataModel?> getStoredUser();

  Future<String?> getStoredToken();
}
