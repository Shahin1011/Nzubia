import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/features/auth/domain/entities/user_entity.dart';

/// Centralized role-based routing utility.
///
/// Navigates the authenticated user to their respective home screen:
/// - `COURIER` -> `/courier-home` (Courier Dashboard)
/// - `AGENT` -> `/agent-home` (Agent Dashboard, or onboarding if unsubmitted)
/// - `CUSTOMER` / `ADMIN` / default -> `/dashboard` (Customer Home)
void navigateBasedOnRole(BuildContext context, UserEntity? user) {
  if (user == null) {
    context.go('/login');
    return;
  }

  final role = user.role.toUpperCase().trim();
  switch (role) {
    case 'COURIER':
      context.go('/p2p/courier/dashboard');
      break;
    case 'AGENT':
      if (user.kycStatus == 'NOT_SUBMITTED') {
        context.go('/agent-onboarding');
      } else {
        context.go('/agent-home');
      }
      break;
    case 'ADMIN':
    case 'CUSTOMER':
    default:
      context.go('/dashboard');
      break;
  }
}
