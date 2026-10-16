import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';

sealed class AuthEvent {
  const AuthEvent();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._loginUseCase) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthLogoutRequested>(_onLogout);
  }

  final LoginUseCase _loginUseCase;

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _loginUseCase(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInitial());
  }
}
