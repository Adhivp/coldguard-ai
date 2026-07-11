import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:code_card_ai/features/auth/domain/usecases/login_usecase.dart';
import 'package:code_card_ai/features/auth/domain/usecases/register_usecase.dart';
import 'package:code_card_ai/features/auth/domain/usecases/logout_usecase.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:code_card_ai/core/usecase/usecase.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  }) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await registerUseCase(
      RegisterParams(name: event.name, email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (_) => emit(const AuthInitial()),
    );
  }
}
