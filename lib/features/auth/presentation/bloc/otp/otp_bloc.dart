import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'otp_event.dart';
import 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final AuthRepository _authRepository;
  Timer? _timer;

  OtpBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const OtpState()) {
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpSubmitted>(_onSubmitted);
    on<OtpResendRequested>(_onResendRequested);
    on<_OtpTimerTick>(_onTimerTick);
    
    _startTimer();
  }

  void _onTimerTick(_OtpTimerTick event, Emitter<OtpState> emit) {
    if (event.countdown <= 0) {
      emit(state.copyWith(resendCountdown: 0, isResendEnabled: true));
    } else {
      emit(state.copyWith(resendCountdown: event.countdown));
    }
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    emit(state.copyWith(code: event.code, status: OtpStatus.initial));
  }

  Future<void> _onSubmitted(OtpSubmitted event, Emitter<OtpState> emit) async {
    emit(state.copyWith(status: OtpStatus.loading));
    try {
      final isVerified = await _authRepository.verifyOtp(state.code);
      if (isVerified) {
        emit(state.copyWith(status: OtpStatus.success));
      } else {
        emit(state.copyWith(
          status: OtpStatus.failure,
          errorMessage: 'Invalid OTP Code',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: OtpStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onResendRequested(OtpResendRequested event, Emitter<OtpState> emit) async {
    if (!state.isResendEnabled) return;

    try {
      await _authRepository.resendOtp();
      emit(state.copyWith(resendCountdown: 180, isResendEnabled: false));
      _startTimer();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to resend OTP'));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newCountdown = state.resendCountdown - 1;
      if (newCountdown <= 0) {
        _timer?.cancel();
        // Since we can't emit from here easily without adding an event or using close check
        if (!isClosed) {
           add(const _OtpTimerTick(0)); // We need an internal event or just updating logic differently.
           // For simplicity let's assume we use a tick event if we were strictly clean, 
           // but `emit` can be called if not closed.
           // However, `emit` is protected.
        }
      } else {
         if (!isClosed) add(_OtpTimerTick(newCountdown));
      }
    });
  }
  
  // To handle timer ticks safely via event loop
  // Need to register this event handler
}

class _OtpTimerTick extends OtpEvent {
  final int countdown;
  const _OtpTimerTick(this.countdown);
  @override
  List<Object> get props => [countdown];
}
