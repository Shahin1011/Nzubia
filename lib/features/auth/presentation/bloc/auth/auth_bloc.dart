import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AppStarted>(_onAppStarted);
    on<UserRefreshRequested>(_onUserRefreshRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onUserRefreshRequested(UserRefreshRequested event, Emitter<AuthState> emit) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthState.authenticated(user));
      }
    } catch (e) {
      // If refresh fails, keep current state or handle as needed
      debugPrint('User refresh failed: $e');
    }
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        // Login to OneSignal (Safely)
        if (!kIsWeb) {
          try {
            OneSignal.login(user.id);
            OneSignal.User.addEmail(user.email);
          } catch (e) {
            debugPrint('OneSignal login failed: $e');
          }
        }
        emit(AuthState.authenticated(user));
      } else {
        emit(AuthState.unauthenticated());
      }
    } catch (_) {
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    if (!kIsWeb) {
      OneSignal.logout();
    }
    emit(AuthState.unauthenticated());
  }
}
