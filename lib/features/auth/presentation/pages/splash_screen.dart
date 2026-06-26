import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/dashboard');
        } else if (state.status == AuthStatus.unauthenticated) {
          try {
            final box = Hive.box('settings');
            final onboardingSeen = box.get('onboarding_seen', defaultValue: false) as bool;
            context.go(onboardingSeen ? '/login' : '/onboarding');
          } catch (_) {
            context.go('/login');
          }
        }
        // AuthStatus.unknown — still loading, stay on splash
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Image.asset(
            isDark ? 'assets/splash_dark.gif' : 'assets/splash_light.gif',
            fit: BoxFit.contain,
            width: 300,
          ),
        ),
      ),
    );
  }
}
