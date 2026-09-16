import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/core/theme/theme_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/services/biometric_service.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_bloc.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_event.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_state.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_event.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_nzubia_global/core/widgets/user_avatar.dart';
import 'package:customer_nzubia_global/core/localization/language_cubit.dart';
import 'package:customer_nzubia_global/core/widgets/offline_error_widget.dart';

import 'package:intl_phone_field/intl_phone_field.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileBloc(profileRepository: sl())..add(LoadUserProfile()),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileAndSettings),
      ),
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          if (state.status == UserProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == UserProfileStatus.failure) {
            return OfflineErrorWidget(
              errorMessage: state.errorMessage ?? 'An error occurred',
              onRetry: () {
                context.read<UserProfileBloc>().add(LoadUserProfile());
                      context.read<AuthBloc>().add(UserRefreshRequested());
              },
            );
          }
          final profile = state.profile;
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }

          final isAgent = profile.role == 'AGENT';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile Header
                UserAvatar(
                  imageUrl: profile.profileImageUrl,
                  name: profile.fullName,
                  radius: 50,
                ),
                const SizedBox(height: 12),
                Text(
                  profile.fullName.isNotEmpty ? profile.fullName : 'N/A',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(profile.email, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                if (profile.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.phoneNumber, style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                ],

                // KYC Status Badge (agents only)
                if (isAgent && profile.kycStatus != null) ...[
                  const SizedBox(height: 12),
                  _buildKycBadge(context, profile.kycStatus!),
                ],

                const SizedBox(height: 24),

                // Agent Info Card
                if (isAgent) ...[
                  _buildAgentInfoCard(context, profile),
                  const SizedBox(height: 16),
                ],

                // Theme Toggle
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.darkMode),
                      secondary: Icon(
                        themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                        color: AppTheme.primaryColor,
                      ),
                      value: themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        context.read<ThemeCubit>().toggleTheme();
                      },
                      activeThumbColor: AppTheme.primaryColor,
                    );
                  },
                ),
                
                // Language Selector
                BlocBuilder<LanguageCubit, Locale>(
                  builder: (context, locale) {
                    return ListTile(
                      title: Text(AppLocalizations.of(context)!.language),
                      leading: const Icon(Icons.language, color: AppTheme.primaryColor),
                      trailing: DropdownButton<String>(
                        value: locale.languageCode,
                        underline: const SizedBox(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            context.read<LanguageCubit>().setLanguage(newValue);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'es', child: Text('Español')),
                          DropdownMenuItem(value: 'fr', child: Text('Français')),
                          DropdownMenuItem(value: 'pt', child: Text('Português')),
                          DropdownMenuItem(value: 'ht', child: Text('Kreyòl')),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),

                // Settings Options
                _buildSettingsItem(
                  context,
                  icon: Icons.person_outline,
                  title: AppLocalizations.of(context)!.editProfile,
                  onTap: () async {
                    final result = await context.push('/profile/edit', extra: profile);
                    if (result == true && context.mounted) {
                      context.read<UserProfileBloc>().add(LoadUserProfile());
                      context.read<AuthBloc>().add(UserRefreshRequested());
                    }
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.notifications_none,
                  title: AppLocalizations.of(context)!.notifications,
                  onTap: () => context.push('/notifications'),
                ),
                // _buildSettingsItem(
                //   context,
                //   icon: Icons.receipt_long,
                //   title: AppLocalizations.of(context)!.paymentHistory,
                //   onTap: () => context.push('/payment-history'),
                // ),
                // if (isAgent)
                //   _buildSettingsItem(
                //     context,
                //     icon: Icons.account_balance_wallet_outlined,
                //     title: AppLocalizations.of(context)!.zelleSettings,
                //     onTap: () => context.push('/profile/payout-settings', extra: profile),
                //   ),

                _buildSettingsItem(
                  context,
                  icon: Icons.security,
                  title: AppLocalizations.of(context)!.security,
                  onTap: () {
                    context.push('/profile/change-password');
                  },
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context)!.helpSupport,
                  onTap: () => _showHelpSupport(context),
                ),
                _buildSettingsItem(
                  context,
                  icon: Icons.delete_forever,
                  title: AppLocalizations.of(context)!.deleteAccount,
                  textColor: Colors.red,
                  onTap: () => _showDeleteAccountDialog(context, profile.role),
                ),
                const Divider(height: 32),
                _buildSettingsItem(
                  context,
                  icon: Icons.logout,
                  title: AppLocalizations.of(context)!.logout,
                  textColor: Colors.red,
                  onTap: () {
                    _showLogoutConfirmation(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKycBadge(BuildContext context, String kycStatus) {
    Color bgColor;
    Color textColor;
    String label;

    textColor = _getKycColor(kycStatus);
    bgColor = textColor.withValues(alpha: 0.15);
    label = _getKycText(context, kycStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _buildAgentInfoCard(BuildContext context, dynamic profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200;
    final labelColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final valueColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context)!.agentInformation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getKycColor(profile.kycStatus).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getKycColor(profile.kycStatus).withValues(alpha: 0.5)),
              ),
              child: Text(
                _getKycText(context, profile.kycStatus),
                style: TextStyle(color: _getKycColor(profile.kycStatus), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Rating
          if (profile.ratingCount > 0) ...[
            Row(
              children: [
                ...List.generate(5, (i) {
                  final starValue = i + 1;
                  if (profile.rating >= starValue) {
                    return const Icon(Icons.star, color: Colors.amber, size: 20);
                  } else if (profile.rating >= starValue - 0.5) {
                    return const Icon(Icons.star_half, color: Colors.amber, size: 20);
                  } else {
                    return Icon(Icons.star_border, color: Colors.amber.withValues(alpha: 0.5), size: 20);
                  }
                }),
                const SizedBox(width: 8),
                Text(
                  '${profile.rating.toStringAsFixed(1)} (${profile.ratingCount} ${AppLocalizations.of(context)!.reviews})',
                  style: TextStyle(color: labelColor, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          /*
          // Company Name
          if (profile.companyName != null && profile.companyName!.isNotEmpty)
            _buildInfoRow(Icons.business, AppLocalizations.of(context)!.company, profile.companyName!, labelColor, valueColor),

          // Agent Type
          if (profile.agentType != null && profile.agentType!.isNotEmpty)
            _buildInfoRow(Icons.badge, AppLocalizations.of(context)!.type, profile.agentType == 'BUSINESS' ? AppLocalizations.of(context)!.business : AppLocalizations.of(context)!.individual, labelColor, valueColor),
          */

          // Service Regions
          if (profile.serviceRegions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.public, size: 18, color: labelColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.serviceRegions, style: TextStyle(color: labelColor, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: profile.serviceRegions.map<Widget>((region) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(region, style: TextStyle(fontSize: 12, color: valueColor)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          /*
          // Years in Business
          if (profile.yearsInBusiness != null)
            _buildInfoRow(Icons.calendar_today, AppLocalizations.of(context)!.yearsInBusinessLabel, '${profile.yearsInBusiness}', labelColor, valueColor),

          // Fleet Size
          if (profile.fleetSize != null)
            _buildInfoRow(Icons.local_shipping, AppLocalizations.of(context)!.fleetSizeLabel, '${profile.fleetSize}', labelColor, valueColor),

          // License Number
          if (profile.licenseNumber != null && profile.licenseNumber!.isNotEmpty)
            _buildInfoRow(Icons.assignment, AppLocalizations.of(context)!.licenseLabel, profile.licenseNumber!, labelColor, valueColor),
          */
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: labelColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
              Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context, String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAccount),
        content: Text(AppLocalizations.of(context)!.areYouSureDelete),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _performAccountDeletion(context);
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.deletingAccount)),
    );
    try {
      final repo = sl<AuthRepository>();
      await repo.deleteAccount();
      if (context.mounted) {
        context.read<AuthBloc>().add(LogoutRequested());
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deletion failed. Please try again.')),
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logout),
        content: Text(AppLocalizations.of(context)!.areYouSureLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
              context.go('/login');
            },
            child: Text(AppLocalizations.of(context)!.logout),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.helpSupportHeader, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primaryColor),
              title: Text(AppLocalizations.of(context)!.emailSupport),
              subtitle: const Text('support@nzubia.com'),
              onTap: () => _launchURL('mailto:support@nzubia.com'),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
              title: Text(AppLocalizations.of(context)!.callUs),
              subtitle: const Text('+1 (617) 648-6936'),
              onTap: () => _launchURL('tel:+16176486936'),
            ),
            // const Divider(),
            // ListTile(
            //   leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryColor),
            //   title: const Text('Privacy Policy'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     context.push('/legal/privacy-policy', extra: 'Privacy Policy');
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.gavel_outlined, color: AppTheme.primaryColor),
            //   title: const Text('Terms of Service'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     context.push('/legal/terms-of-use', extra: 'Terms of Service');
            //   },
            // ),
            // const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }

  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _SecuritySettingsDialog(),
    );
  }

  void _showPayoutSettings(BuildContext context, dynamic profile) {
    context.push('/profile/payout-settings', extra: profile);
  }

  Color _getKycColor(String? kycStatus) {
    switch (kycStatus) {
      case 'VERIFIED': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getKycText(BuildContext context, String? kycStatus) {
    if (kycStatus == 'VERIFIED') return AppLocalizations.of(context)!.verified;
    if (kycStatus == 'PENDING') return AppLocalizations.of(context)!.pending;
    if (kycStatus == 'REJECTED') return AppLocalizations.of(context)!.verificationFailed;
    return AppLocalizations.of(context)!.notSubmitted;
  }
}

class _PayoutSettingsDialog extends StatefulWidget {
  final dynamic profile;
  const _PayoutSettingsDialog({required this.profile});

  @override
  State<_PayoutSettingsDialog> createState() => _PayoutSettingsDialogState();
}

class _PayoutSettingsDialogState extends State<_PayoutSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late String _currentPhone;
  late String _preferredMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.profile.zelleEmail);
    _currentPhone = widget.profile.zellePhone ?? '';
    _preferredMethod = widget.profile.preferredPayoutMethod ?? 'STRIPE';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await sl<AuthRepository>().updateAgentProfile(
        preferredPayoutMethod: _preferredMethod,
        zelleEmail: _preferredMethod == 'ZELLE' ? _emailController.text : null,
        zellePhone: _preferredMethod == 'ZELLE' ? _currentPhone : null,
      );
      if (mounted) {
        // Refresh profile in Bloc
        context.read<UserProfileBloc>().add(LoadUserProfile());
        context.read<AuthBloc>().add(UserRefreshRequested());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.payoutInfoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: const TextStyle(color: Colors.white)), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.zelleSettings),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _preferredMethod,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.payoutMethod,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
                items: [
                  DropdownMenuItem(value: 'STRIPE', child: Text(AppLocalizations.of(context)!.stripePayout)),
                  DropdownMenuItem(value: 'ZELLE', child: Text(AppLocalizations.of(context)!.zellePayout)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _preferredMethod = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              if (_preferredMethod == 'ZELLE') ...[
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.zelleEmail,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (_preferredMethod == 'ZELLE') {
                      if (val == null || val.isEmpty) return AppLocalizations.of(context)!.requiredField;
                      if (!val.contains('@')) return AppLocalizations.of(context)!.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  initialValue: _currentPhone.length > 2 && _currentPhone.startsWith('+') ? _currentPhone.substring(3) : _currentPhone,
                  initialCountryCode: 'US', // Default but searchable
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.zellePhoneNumber,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (phone) {
                    _currentPhone = phone.completeNumber;
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.stripePayoutInfo,
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}

class _SecuritySettingsDialog extends StatefulWidget {
  const _SecuritySettingsDialog();

  @override
  State<_SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<_SecuritySettingsDialog> {
  bool _biometricsEnabled = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final available = await sl<BiometricService>().isBiometricAvailable();
    final enabled = await sl<AuthRepository>().isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
        _biometricsEnabled = enabled;
      });
    }
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your password to enable biometric login.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Security Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /*
          if (_isBiometricAvailable) ...[
            SwitchListTile(
              title: const Text('Biometric Login'),
              subtitle: const Text('Use FaceID/Fingerprint'),
              value: _biometricsEnabled,
              onChanged: (val) async {
                if (val) {
                  // Prompt for password to enable
                  final password = await _promptForPassword();
                  if (password != null && password.isNotEmpty) {
                    final email = context.read<AuthBloc>().state.user?.email;
                    if (email != null) {
                      await sl<AuthRepository>().saveBiometricCredentials(email, password);
                      await sl<AuthRepository>().setBiometricsEnabled(true);
                      setState(() => _biometricsEnabled = true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric login enabled')));
                      }
                    }
                  }
                } else {
                  await sl<AuthRepository>().setBiometricsEnabled(false);
                  setState(() => _biometricsEnabled = false);
                }
              },
            ),
            const Divider(),
          ],
          */
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile/change-password');
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
