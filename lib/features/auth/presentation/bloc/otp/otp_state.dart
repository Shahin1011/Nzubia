import 'package:equatable/equatable.dart';

enum OtpStatus { initial, loading, success, failure }

class OtpState extends Equatable {
  final OtpStatus status;
  final String code;
  final String? errorMessage;
  final bool isResendEnabled;
  final int resendCountdown;

  const OtpState({
    this.status = OtpStatus.initial,
    this.code = '',
    this.errorMessage,
    this.isResendEnabled = false,
    this.resendCountdown = 180,
  });

  OtpState copyWith({
    OtpStatus? status,
    String? code,
    String? errorMessage,
    bool? isResendEnabled,
    int? resendCountdown,
  }) {
    return OtpState(
      status: status ?? this.status,
      code: code ?? this.code,
      errorMessage: errorMessage ?? this.errorMessage,
      isResendEnabled: isResendEnabled ?? this.isResendEnabled,
      resendCountdown: resendCountdown ?? this.resendCountdown,
    );
  }

  @override
  List<Object?> get props => [status, code, errorMessage, isResendEnabled, resendCountdown];
}
