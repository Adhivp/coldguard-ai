import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:code_card_ai/core/network/dio_client.dart';
import 'package:code_card_ai/core/network/network_info.dart';
import 'package:code_card_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:code_card_ai/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:code_card_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:code_card_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:code_card_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:code_card_ai/features/auth/domain/usecases/register_usecase.dart';
import 'package:code_card_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => DioClient(sl()));

  // External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());
}
