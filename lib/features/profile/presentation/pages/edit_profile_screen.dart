import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_bloc.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_event.dart';
import 'package:customer_nzubia_global/features/profile/presentation/bloc/user_profile/user_profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfileEntity profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber);
    _companyController = TextEditingController(text: widget.profile.companyName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme aware styles
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colors for input fields
    final inputFillColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    final inputBorderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300;
    final iconColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final labelColor = isDark ? Colors.white60 : Colors.grey.shade700;
    final textColor = isDark ? Colors.white : Colors.black87;

    final isAgent = widget.profile.role == 'AGENT';

    return BlocProvider(
      create: (context) => UserProfileBloc(profileRepository: sl()),
      child: BlocConsumer<UserProfileBloc, UserProfileState>(
        listener: (context, state) {
          if (state.status == UserProfileStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile Updated Successfully')),
            );
            context.pop(true); 
          }
          if (state.status == UserProfileStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Update failed')),
            );
          }
          if (state.changeRequestMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.changeRequestMessage!)),
            );
            if (state.changeRequestMessage!.contains('successfully')) {
              context.pop(true);
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Profile'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Info banner for agents
                        if (isAgent) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Changes to your profile require admin approval',
                                    style: TextStyle(color: Colors.blue, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: inputFillColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: inputBorderColor),
                          ),
                          child: Column(
                            children: [
                              // Email (read-only)
                              TextField(
                                controller: TextEditingController(text: widget.profile.email),
                                enabled: false,
                                style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: iconColor),
                                  labelStyle: TextStyle(color: labelColor),
                                  border: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                  disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor.withValues(alpha: 0.5))),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Full Name
                              TextField(
                                controller: _nameController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person, color: iconColor),
                                  labelStyle: TextStyle(color: labelColor),
                                  border: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Phone Number
                              TextField(
                                controller: _phoneController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone, color: iconColor),
                                  labelStyle: TextStyle(color: labelColor),
                                  border: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                ),
                                keyboardType: TextInputType.phone,
                              ),

                              /*
                              // Company Name (agents only)
                              if (isAgent) ...[ 
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _companyController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: 'Company Name',
                                    prefixIcon: Icon(Icons.business, color: iconColor),
                                    labelStyle: TextStyle(color: labelColor),
                                    border: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: inputBorderColor)),
                                  ),
                                ),
                              ],
                              */
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.status == UserProfileStatus.loading
                          ? null
                          : () {
                              if (isAgent) {
                                // For agents: submit change request
                                final changes = <String, dynamic>{};
                                
                                if (_nameController.text != widget.profile.fullName) {
                                  changes['full_name'] = {
                                    'old': widget.profile.fullName,
                                    'new': _nameController.text,
                                  };
                                }
                                
                                if (_phoneController.text != widget.profile.phoneNumber) {
                                  changes['phone'] = {
                                    'old': widget.profile.phoneNumber,
                                    'new': _phoneController.text,
                                  };
                                }
                                
                                if (_companyController.text != (widget.profile.companyName ?? '')) {
                                  changes['company_name'] = {
                                    'old': widget.profile.companyName ?? '',
                                    'new': _companyController.text,
                                  };
                                }

                                if (changes.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No changes detected')),
                                  );
                                  return;
                                }

                                context.read<UserProfileBloc>().add(SubmitChangeRequest(changes));
                              } else {
                                // For customers: direct update
                                final updatedProfile = UserProfileEntity(
                                  id: widget.profile.id,
                                  email: widget.profile.email,
                                  fullName: _nameController.text,
                                  phoneNumber: _phoneController.text,
                                  role: widget.profile.role,
                                  profileImageUrl: widget.profile.profileImageUrl,
                                );
                                context.read<UserProfileBloc>().add(UpdateUserProfile(updatedProfile));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white, 
                      ),
                      child: state.status == UserProfileStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isAgent ? 'Submit Change Request' : 'Save Changes',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
