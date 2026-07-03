import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_bloc.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_event.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_state.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentPayoutSettingsScreen extends StatefulWidget {
  final UserProfileEntity profile;

  const AgentPayoutSettingsScreen({super.key, required this.profile});

  @override
  State<AgentPayoutSettingsScreen> createState() => _AgentPayoutSettingsScreenState();
}

class _AgentPayoutSettingsScreenState extends State<AgentPayoutSettingsScreen> {
  late String _preferredMethod;
  late TextEditingController _zelleEmailController;
  late TextEditingController _zellePhoneController;

  @override
  void initState() {
    super.initState();
    _preferredMethod = widget.profile.preferredPayoutMethod ?? 'STRIPE';
    _zelleEmailController = TextEditingController(text: widget.profile.zelleEmail);
    _zellePhoneController = TextEditingController(text: widget.profile.zellePhone);
  }

  @override
  void dispose() {
    _zelleEmailController.dispose();
    _zellePhoneController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedProfile = UserProfileEntity(
      id: widget.profile.id,
      email: widget.profile.email,
      fullName: widget.profile.fullName,
      phoneNumber: widget.profile.phoneNumber,
      role: widget.profile.role,
      profileImageUrl: widget.profile.profileImageUrl,
      preferredPayoutMethod: _preferredMethod,
      zelleEmail: _zelleEmailController.text.trim(),
      zellePhone: _zellePhoneController.text.trim(),
      companyName: widget.profile.companyName,
      businessAddress: widget.profile.businessAddress,
      agentType: widget.profile.agentType,
      serviceRegions: widget.profile.serviceRegions,
      rating: widget.profile.rating,
      ratingCount: widget.profile.ratingCount,
      yearsInBusiness: widget.profile.yearsInBusiness,
      fleetSize: widget.profile.fleetSize,
      licenseNumber: widget.profile.licenseNumber,
      kycStatus: widget.profile.kycStatus,
    );

    context.read<UserProfileBloc>().add(UpdateUserProfile(updatedProfile));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<UserProfileBloc, UserProfileState>(
      listener: (context, state) {
        if (state.status == UserProfileStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.payoutInfoUpdated)),
          );
          Navigator.pop(context);
        } else if (state.status == UserProfileStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Update failed')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.payoutMethod),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.preferredPayoutMethod,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.choosePayoutMethod,
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 24),
              _buildMethodCard(
                context,
                title: AppLocalizations.of(context)!.stripeConnect,
                subtitle: 'Automatic payouts to your linked bank account',
                value: 'STRIPE',
                icon: Icons.account_balance,
              ),
              const SizedBox(height: 16),
              _buildMethodCard(
                context,
                title: AppLocalizations.of(context)!.zelleTransfer,
                subtitle: 'Manual payouts via Zelle email or phone',
                value: 'ZELLE',
                icon: Icons.payments_outlined,
              ),
              if (_preferredMethod == 'ZELLE') ...[
                const SizedBox(height: 32),
                Text(
                  'Zelle Details',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _zelleEmailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.zelleEmail,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _zellePhoneController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.zellePhoneNumber,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<UserProfileBloc, UserProfileState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == UserProfileStatus.loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state.status == UserProfileStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(AppLocalizations.of(context)!.savePayoutInfo),
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

  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _preferredMethod == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _preferredMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : theme.dividerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : theme.iconTheme.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
