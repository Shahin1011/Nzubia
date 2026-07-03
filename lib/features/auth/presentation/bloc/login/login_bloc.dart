import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginOtpChanged>(_onOtpChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginVerifyOtpSubmitted>(_onVerifyOtpSubmitted);
    on<LoginReset>(_onReset);
    on<LoginResendOtp>(_onResendOtp);
    /*
    on<LoginWithBiometrics>(_onWithBiometrics);
    */
  }

  /*
  Future<void> _onWithBiometrics(LoginWithBiometrics event, Emitter<LoginState> emit) async {
    final biometricService = sl<BiometricService>();
    final isAvailable = await biometricService.isBiometricAvailable();
    if (!isAvailable) {
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: 'Biometrics not available'));
      return;
    }

    final isEnabled = await _authRepository.isBiometricsEnabled();
    if (!isEnabled) {
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: 'Biometric login is not enabled. Please login manually first.'));
      return;
    }

    final authenticated = await biometricService.authenticate(
      reason: 'Please authenticate to login to your Nzubia account',
    );

    if (authenticated) {
      emit(state.copyWith(status: LoginStatus.loading));
      try {
        final user = await _authRepository.loginWithBiometrics();
        
        await sl<MessagingRepository>().initialize();
        if (!kIsWeb) {
           OneSignal.login(user.id);
        }

        emit(state.copyWith(status: LoginStatus.success));
      } catch (e) {
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: e.toString()));
      }
    }
  }
  */

  Future<void> _onResendOtp(LoginResendOtp event, Emitter<LoginState> emit) async {
    try {
      await _authRepository.resendOtp();
      emit(state.copyWith(errorMessage: 'OTP Sent Again', status: LoginStatus.initial));
      // Hack to trigger listener again if needed, or rely on distinct checks.
      // If status didn't change, listener might not fire if it checks status change.
      // But errorMessage changed.
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onReset(LoginReset event, Emitter<LoginState> emit) {
    emit(state.copyWith(
      status: LoginStatus.initial,
      isOtpRequired: false,
      errorMessage: '',
      otp: '',
    ));
  }

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(email: event.email, status: LoginStatus.initial));
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(password: event.password, status: LoginStatus.initial));
  }

  void _onOtpChanged(LoginOtpChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(otp: event.otp, status: LoginStatus.initial));
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final user = await _authRepository.login(state.email, state.password);
      // Initialize Messaging Socket on successful login (Direct login)
      await sl<MessagingRepository>().initialize();
      
      // OneSignal Login
      if (!kIsWeb) {
        OneSignal.login(user.id);
      }
      
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      if (e.toString().contains('OTP_REQUIRED')) {
        emit(state.copyWith(
          status: LoginStatus.initial,
          isOtpRequired: true,
          errorMessage: 'OTP Sent to your email/phone',
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    }
  }

  Future<void> _onVerifyOtpSubmitted(LoginVerifyOtpSubmitted event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      final user = await _authRepository.getCurrentUser(); // We need user for OneSignal login
      final success = await _authRepository.verifyOtp(state.otp);
      if (success) {
        // Initialize Messaging Socket on successful login (OTP)
        await sl<MessagingRepository>().initialize();
        
        if (user != null && !kIsWeb) {
           OneSignal.login(user.id);
        }
        
        emit(state.copyWith(status: LoginStatus.success));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Invalid OTP',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
