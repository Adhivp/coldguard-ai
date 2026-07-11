import 'package:dartz/dartz.dart';
import 'package:code_card_ai/core/error/exceptions.dart';
import 'package:code_card_ai/core/error/failures.dart';
import 'package:code_card_ai/core/network/network_info.dart';
import 'package:code_card_ai/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:code_card_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:code_card_ai/features/auth/domain/entities/user_entity.dart';
import 'package:code_card_ai/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.login(
          email: email,
          password: password,
        );
        if (remoteUser.token != null) {
          await localDataSource.cacheToken(remoteUser.token!);
        }
        return Right(remoteUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ConnectionFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteUser = await remoteDataSource.register(
          name: name,
          email: email,
          password: password,
        );
        if (remoteUser.token != null) {
          await localDataSource.cacheToken(remoteUser.token!);
        }
        return Right(remoteUser);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ConnectionFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
