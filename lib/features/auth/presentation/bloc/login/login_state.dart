import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String email;
  final String password;
  final String? errorMessage;
  final bool isOtpRequired;
  final String otp;

  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
    this.errorMessage,
    this.isOtpRequired = false,
    this.otp = '',
  });

  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? password,
    String? errorMessage,
    bool? isOtpRequired,
    String? otp,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
      isOtpRequired: isOtpRequired ?? this.isOtpRequired,
      otp: otp ?? this.otp,
    );
  }

  @override
  List<Object?> get props => [status, email, password, errorMessage, isOtpRequired, otp];
}
