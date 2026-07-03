import 'package:flutter/material.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/login/login_event.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/login/login_state.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_event.dart';

import '../../../../core/theme/custom_theme_extension.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(authRepository: sl()),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor: theme.scaffoldBackgroundColor, // Handled by theme
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                 final user = state.user;
                 if (user?.role.toUpperCase() == 'AGENT') {
                    if (user?.kycStatus == 'NOT_SUBMITTED') {
                       context.go('/agent-onboarding');
                    } else {
                       context.go('/agent-dashboard');
                    }
                 } else {
                    context.go('/dashboard');
                 }
              }
            },
          ),
          BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state.status == LoginStatus.failure) {
                final lowerCaseError = (state.errorMessage ?? '').toLowerCase();
                final rawError = state.errorMessage ?? AppLocalizations.of(context)?.authenticationFailure ?? "Authentication failed";
                
                String cleanMessage = rawError;
                if (rawError.contains('DioException')) {
                   final match = RegExp(r'DioException \[[^\]]+\]: (.*)').firstMatch(rawError);
                   if (match != null) cleanMessage = match.group(1) ?? rawError;
                } else if (rawError.startsWith('Exception:')) {
                   cleanMessage = rawError.replaceFirst('Exception:', '').trim();
                }

                final isNetworkError = lowerCaseError.contains('internet') || 
                                       lowerCaseError.contains('connection timeout') ||
                                       lowerCaseError.contains('connection error') ||
                                       lowerCaseError.contains('socket') ||
                                       lowerCaseError.contains('network') ||
                                       lowerCaseError.contains('failed host lookup');

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(isNetworkError ? Icons.signal_wifi_off : Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isNetworkError 
                                ? 'No Internet Connection. Please check your network and try again.'
                                : cleanMessage,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    ),
                  );
              }
               if (state.isOtpRequired && state.errorMessage != null && state.errorMessage!.contains('OTP Sent')) {
                 ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: theme.extension<AppColorsExtension>()?.neonLime ?? Colors.green,
                    ),
                  );
               }

              if (state.status == LoginStatus.success) {
                // Trigger AuthBloc to refresh and update the global auth state
                context.read<AuthBloc>().add(AppStarted());
              }
            },
          ),
        ],
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                height: size.height * 0.35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/splash_dark.gif'
                        : 'assets/splash_light.gif',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.fromBorderSide(theme.inputDecorationTheme.enabledBorder!.borderSide),
                ),
                child: BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.welcomeBack ?? "Welcome Back",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isOtpRequired ? AppLocalizations.of(context)?.enterOtpSentTo(state.email) ?? "Enter OTP sent to ${state.email}" : AppLocalizations.of(context)?.signInToManageShipments ?? "Sign in to manage your shipments",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 40),

                        if (!state.isOtpRequired) ...[
                          _EmailInput(
                            controller: _emailController,
                            enabled: state.status != LoginStatus.loading,
                          ),
                          const SizedBox(height: 16),
                          _PasswordInput(
                            controller: _passwordController,
                            enabled: state.status != LoginStatus.loading,
                          ),
                        ] else ...[
                          _OtpInput(
                            controller: _otpController,
                            enabled: state.status != LoginStatus.loading,
                          ),
                        ],

                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _LoginButton(
                                email: _emailController.text,
                                password: _passwordController.text,
                                otp: _otpController.text,
                              ),
                            ),
                            if (!state.isOtpRequired) ...[
                              const SizedBox(width: 12),
                              // _BiometricButton(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (!state.isOtpRequired)
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text(AppLocalizations.of(context)?.dontHaveAccountSignUp ?? "Sign Up as a customer"),
                          )
                        else
                          TextButton(
                            onPressed: () {
                              _otpController.clear();
                              context.read<LoginBloc>().add(const LoginReset());
                            },
                            child: Text(AppLocalizations.of(context)?.backToLogin ?? "Back to Login"),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _EmailInput({
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('loginForm_emailInput_textField'),
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onChanged: (email) => context.read<LoginBloc>().add(LoginEmailChanged(email)),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)?.email,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const _PasswordInput({
    required this.controller,
    required this.enabled,
  });

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('loginForm_passwordInput_textField'),
      controller: widget.controller,
      enabled: widget.enabled,
      onChanged: (password) => context.read<LoginBloc>().add(LoginPasswordChanged(password)),
      obscureText: _isObscure,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => context.read<LoginBloc>().add(const LoginSubmitted()),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)?.password,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _OtpInput({
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('loginForm_otpInput_textField'),
          controller: controller,
          enabled: enabled,
          onChanged: (otp) => context.read<LoginBloc>().add(LoginOtpChanged(otp)),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => context.read<LoginBloc>().add(const LoginVerifyOtpSubmitted()),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.oneTimePassword,
            hintText: '123456',
            prefixIcon: const Icon(Icons.security),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: enabled ? () => context.read<LoginBloc>().add(const LoginResendOtp()) : null,
            child: Text(AppLocalizations.of(context)?.resendCode ?? "Resend Code"),
          ),
        ),
      ],
    );
  }
}


class _LoginButton extends StatelessWidget {
  final String email;
  final String password;
  final String otp;

  const _LoginButton({
    required this.email,
    required this.password,
    required this.otp,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final canSubmit = state.isOtpRequired
            ? otp.trim().length >= 4
            : email.trim().isNotEmpty && password.trim().isNotEmpty;

        return state.status == LoginStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                key: const Key('loginForm_continue_raisedButton'),
                onPressed: !canSubmit
                    ? null
                    : () {
                  if (state.isOtpRequired) {
                    context.read<LoginBloc>().add(const LoginVerifyOtpSubmitted());
                  } else {
                    context.read<LoginBloc>().add(const LoginSubmitted());
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  state.isOtpRequired ? (AppLocalizations.of(context)?.verifyOtp ?? "Verify OTP") : (AppLocalizations.of(context)?.login ?? "Login"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
      },
    );
  }
}
/*
class _BiometricButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        return FutureBuilder<bool>(
          // Check BOTH availability AND if user enabled it in profile
          future: Future.wait<bool>([
            sl<BiometricService>().isBiometricAvailable(),
            sl<AuthRepository>().isBiometricsEnabled(),
          ]).then((results) => results[0] && results[1]),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return IconButton(
                onPressed: state.status == LoginStatus.loading
                    ? null
                    : () => context.read<LoginBloc>().add(const LoginWithBiometrics()),
                icon: const Icon(Icons.fingerprint, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}
*/
