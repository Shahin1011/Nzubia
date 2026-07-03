import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/register/register_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/register/register_event.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/register/register_state.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:customer_nzubia_global/l10n/app_localizations.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(authRepository: sl()),
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  bool _smsConsent = false;

  @override
  void initState() {
    super.initState();
    // Default role is always CUSTOMER for App Store compliance (Guideline 3.1.1)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegisterBloc>().add(const RegisterRoleChanged('CUSTOMER'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state.status == RegisterStatus.failure) {
            // Parse the raw error string to extract the clean backend message
            String rawError = state.errorMessage ?? 'Registration failed. Please try again.';
            
            // The Dio error often wraps the message like "Exception: ... message: <actual message>"
            String cleanMessage = rawError;
            if (rawError.contains('"message"')) {
              // Try to extract from JSON-like structure
              final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(rawError);
              if (msgMatch != null) cleanMessage = msgMatch.group(1) ?? rawError;
            } else if (rawError.contains('message:')) {
              // Simple key:value extraction
              final parts = rawError.split('message:');
              if (parts.length > 1) cleanMessage = parts.last.trim().split('\n').first.trim();
            } else if (rawError.contains('DioException')) {
               final match = RegExp(r'DioException \[[^\]]+\]: (.*)').firstMatch(rawError);
               if (match != null) cleanMessage = match.group(1) ?? rawError;
            } else if (rawError.startsWith('Exception:')) {
              cleanMessage = rawError.replaceFirst('Exception:', '').trim();
            }

            final lowerCaseError = (state.errorMessage ?? '').toLowerCase();
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
          if (state.status == RegisterStatus.success) {
            if (state.isVerified) {
              context.go('/dashboard');
            } else {
              context.push('/otp');
            }
          }
        },

        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/splash_dark.gif'
                        : 'assets/splash_light.gif',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.createAccount,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.joinNetwork,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                // Logo (GIF)

                const SizedBox(height: 28),
                _EmailInput(),
                const SizedBox(height: 16),
                _PhoneInput(
                  onConsentChanged: (val) => setState(() => _smsConsent = val),
                  smsConsent: _smsConsent,
                ),
                const SizedBox(height: 16),
                _PasswordInput(),
                const SizedBox(height: 24),
                /*
                _BusinessSection(
                  isBusiness: _isBusiness,
                  onIsBusinessChanged: (val) {
                    setState(() => _isBusiness = val);
                    context.read<RegisterBloc>().add(RegisterIsBusinessChanged(val));
                  },
                  onCompanyNameChanged: (val) {
                    context.read<RegisterBloc>().add(RegisterCompanyNameChanged(val));
                  },
                  companyNameController: _companyNameController,
                  selectedRole: _selectedRole,
                ),
                */
                const SizedBox(height: 24),
                _RegisterButton(smsConsent: _smsConsent),
                /*
                const SizedBox(height: 48),
                _AgentRegistrationPrompt(),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _EmailInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) => previous.email != current.email,
      builder: (context, state) {
        return TextField(
          key: const Key('registerForm_emailInput_textField'),
          onChanged: (email) => context.read<RegisterBloc>().add(RegisterEmailChanged(email)),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.email,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        );
      },
    );
  }
}

class _PhoneInput extends StatelessWidget {
  final ValueChanged<bool> onConsentChanged;
  final bool smsConsent;

  const _PhoneInput({
    required this.onConsentChanged,
    required this.smsConsent,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) => previous.phone != current.phone,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntlPhoneField(
              key: const Key('registerForm_phoneInput_textField'),
              onChanged: (phone) => context.read<RegisterBloc>().add(RegisterPhoneChanged(phone.completeNumber)),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.phoneNumber,
                // prefixIcon is handled by the flag selector in IntlPhoneField
              ),
              initialCountryCode: 'US',
            ),
            const SizedBox(height: 8),
            // SMS Consent Checkbox
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: smsConsent
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    key: const Key('registerForm_smsConsent_checkbox'),
                    value: smsConsent,
                    onChanged: (val) => onConsentChanged(val ?? false),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(
                              text: 'I agree to receive automated SMS from Nzubia regarding shipment milestones and security alerts. Msg & Data rates may apply. Reply STOP to opt-out. See our ',
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl('https://nzubia.com/privacy-policy'),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Terms of Use',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _launchUrl('https://nzubia.com/terms-of-use'),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PasswordInput extends StatefulWidget {
  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) => previous.password != current.password,
      builder: (context, state) {
        return TextField(
          key: const Key('registerForm_passwordInput_textField'),
          onChanged: (password) => context.read<RegisterBloc>().add(RegisterPasswordChanged(password)),
          obscureText: _isObscure,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
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
      },
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool smsConsent;
  const _RegisterButton({required this.smsConsent});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        return state.status == RegisterStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                key: const Key('registerForm_continue_raisedButton'),
                onPressed: smsConsent
                    ? () {
                        context.read<RegisterBloc>().add(const RegisterSubmitted());
                      }
                    : null,
                child: Text(AppLocalizations.of(context)!.signUp),
              );
      },
    );
  }
}

/*
class _BusinessSection extends StatelessWidget {
  final bool isBusiness;
  final ValueChanged<bool> onIsBusinessChanged;
  final ValueChanged<String> onCompanyNameChanged;
  final TextEditingController companyNameController;
  final String selectedRole;

  const _BusinessSection({
    required this.isBusiness,
    required this.onIsBusinessChanged,
    required this.onCompanyNameChanged,
    required this.companyNameController,
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedRole != 'CUSTOMER') return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.registerAsBusiness),
            Switch(
              value: isBusiness,
              onChanged: onIsBusinessChanged,
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
        if (isBusiness) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: companyNameController,
            onChanged: onCompanyNameChanged,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.companyName,
              prefixIcon: const Icon(Icons.business_outlined),
            ),
          ),
        ],
      ],
    );
  }
}

class _AgentRegistrationPrompt extends StatelessWidget {
  const _AgentRegistrationPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            height: 1.5,
          ),
          children: [
            const TextSpan(text: "Are you an Agent? To join the Nzubia provider network, please visit our web portal at "),
            TextSpan(
              text: "nzubia.com/register",
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final url = Uri.parse('https://nzubia.com/register');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
            ),
            const TextSpan(text: " to complete your business verification."),
          ],
        ),
      ),
    );
  }
}
*/
