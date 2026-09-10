import 'package:equatable/equatable.dart';

enum RegisterStatus { initial, loading, success, failure }

class RegisterState extends Equatable {
  final RegisterStatus status;
  final String email;
  final String phone;
  final String password;
  final String role;
  final bool isBusiness;
  final String companyName;
  final bool isVerified;
  final String? errorMessage;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.email = '',
    this.phone = '',
    this.password = '',
    this.role = 'CUSTOMER',
    this.isBusiness = false,
    this.companyName = '',
    this.isVerified = false,
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterStatus? status,
    String? email,
    String? phone,
    String? password,
    String? role,
    bool? isBusiness,
    String? companyName,
    bool? isVerified,
    String? errorMessage,
  }) {
    return RegisterState(
      status: status ?? this.status,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      isBusiness: isBusiness ?? this.isBusiness,
      companyName: companyName ?? this.companyName,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, email, phone, password, role, isBusiness, companyName, isVerified, errorMessage];
}
