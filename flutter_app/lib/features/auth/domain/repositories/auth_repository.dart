import 'package:dartz/dartz.dart';
import 'package:code_card_ai/core/error/failures.dart';
import 'package:code_card_ai/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> logout();
}
