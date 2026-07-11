import 'package:code_card_ai/core/network/dio_client.dart';
import 'package:code_card_ai/core/error/exceptions.dart';
import 'package:code_card_ai/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Simulating remote authentication request with a short delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (email == 'user@example.com' && password == 'password123') {
      return UserModel(
        id: 'mock-uuid-12345',
        email: email,
        name: 'John Doe',
        token: 'mock-jwt-token-xyz',
      );
    } else {
      throw const ServerException('Invalid email or password. Use user@example.com / password123');
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (email.contains('@')) {
      return UserModel(
        id: 'mock-uuid-98765',
        email: email,
        name: name,
        token: 'mock-jwt-token-register',
      );
    } else {
      throw const ServerException('Registration failed: Invalid email format.');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulated remote logout
  }
}
