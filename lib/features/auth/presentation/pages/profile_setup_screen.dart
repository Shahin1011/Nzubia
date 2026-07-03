import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/profile_setup/profile_setup_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/profile_setup/profile_setup_event.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/profile_setup/profile_setup_state.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_state.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_event.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileSetupBloc(authRepository: sl()),
      child: const ProfileSetupView(),
    );
  }
}

class ProfileSetupView extends StatelessWidget {
  const ProfileSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated && state.user != null) {
                 final user = state.user!;
                 if (user.role.toUpperCase() == 'AGENT') {
                    if (user.kycStatus == 'NOT_SUBMITTED') {
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
          BlocListener<ProfileSetupBloc, ProfileSetupState>(
            listener: (context, state) {
              if (state.status == ProfileSetupStatus.failure) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(state.errorMessage ?? 'Update Failed')),
                  );
              }
              if (state.status == ProfileSetupStatus.success) {
                // Trigger Auth Refresh to get updated Profile/Role data
                context.read<AuthBloc>().add(AppStarted());
              }
            },
          ),
        ],
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us about yourself',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _NameInput(),
                const SizedBox(height: 24),
                // _BusinessFields(),
                // const SizedBox(height: 16),

                // _BusinessFields(),
                const SizedBox(height: 32),
                _SubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Removed BlocBuilder to prevent rebuild/focus loss on typing
    return TextField(
      key: const Key('profileForm_nameInput_textField'),
      onChanged: (name) => context.read<ProfileSetupBloc>().add(ProfileNameChanged(name)),
      decoration: const InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
  }
}

// class _BusinessToggle extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AuthBloc, AuthState>(
//       builder: (context, authState) {
//         if (authState.user?.role.toUpperCase() == 'AGENT') {
//           return const SizedBox.shrink();
//         }
//         return BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
//           buildWhen: (previous, current) => previous.isBusinessAccount != current.isBusinessAccount,
//           builder: (context, state) {
//             return SwitchListTile(
//               title: const Text('I am a Business Exporter'),
//               value: state.isBusinessAccount,
//               onChanged: (value) => context.read<ProfileSetupBloc>().add(ProfileBusinessToggleChanged(value)),
//               activeColor: AppTheme.primaryColor,
//             );
//           },
//         );
//       }
//     );
//   }
// }

/*
class _BusinessFields extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
      // Only rebuild if the visibility of the section changes
      buildWhen: (previous, current) => previous.isBusinessAccount != current.isBusinessAccount,
      builder: (context, state) {
        if (!state.isBusinessAccount) return const SizedBox.shrink();
        
        return Column(
          children: [
            TextField(
              key: const Key('profileForm_companyInput_textField'),
              onChanged: (name) => context.read<ProfileSetupBloc>().add(ProfileCompanyChanged(name)),
              decoration: const InputDecoration(
                labelText: 'Company Name',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('profileForm_einInput_textField'),
              onChanged: (ein) => context.read<ProfileSetupBloc>().add(ProfileEinChanged(ein)),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'EIN / Tax ID',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
          ],
        );
      },
    );
  }
}
*/

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
      builder: (context, state) {
        return state.status == ProfileSetupStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                key: const Key('profileForm_submit_raisedButton'),
                onPressed: () {
                  context.read<ProfileSetupBloc>().add(const ProfileSetupSubmitted());
                },
                child: const Text('Complete Setup'),
              );
      },
    );
  }
}
