import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/otp/otp_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/otp/otp_event.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/otp/otp_state.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OtpBloc(authRepository: sl()),
      child: const OtpVerificationView(),
    );
  }
}

class OtpVerificationView extends StatelessWidget {
  const OtpVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<OtpBloc, OtpState>(
        listener: (context, state) {
          if (state.status == OtpStatus.failure) {
            final theme = Theme.of(context);
            final lowerCaseError = (state.errorMessage ?? '').toLowerCase();
            final rawError = state.errorMessage ?? 'Verification Failure';
            
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
                  duration: const Duration(seconds: 4),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: Row(
                    children: [
                      Icon(isNetworkError ? Icons.signal_wifi_off : Icons.error_outline, color: Colors.white, size: 22),
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
                ),
              );
          }
          if (state.status == OtpStatus.success) {
            context.go('/profile-setup');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Enter Verification Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a code to your phone and Email',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.darkGray,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _OtpInput(),
              const SizedBox(height: 24),
              _VerifyButton(),
              const SizedBox(height: 24),
              _ResendButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc, OtpState>(
      buildWhen: (previous, current) => previous.code != current.code,
      builder: (context, state) {
        return TextField(
          key: const Key('otpForm_codeInput_textField'),
          onChanged: (code) => context.read<OtpBloc>().add(OtpCodeChanged(code)),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
        );
      },
    );
  }
}

class _VerifyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        return ElevatedButton(
          key: const Key('otpForm_verify_raisedButton'),
          onPressed: state.status == OtpStatus.loading
              ? null
              : () {
                  context.read<OtpBloc>().add(const OtpSubmitted());
                },
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: state.status == OtpStatus.loading
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : const Text('Verify'),
        );
      },
    );
  }
}

class _ResendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OtpBloc, OtpState>(
      builder: (context, state) {
        if (state.isResendEnabled) {
          return TextButton(
            onPressed: () {
              context.read<OtpBloc>().add(const OtpResendRequested());
            },
            child: const Text('Resend Code'),
          );
        } else {
          final minutes = (state.resendCountdown ~/ 60).toString().padLeft(2, '0');
          final seconds = (state.resendCountdown % 60).toString().padLeft(2, '0');
          return  Text(
            'Resend code in $minutes:$seconds',
            textAlign: TextAlign.center,
             style: const TextStyle(color: AppTheme.darkGray),
          );
        }
      },
    );
  }
}
