part of 'p2p_onboarding_bloc.dart';

abstract class P2pOnboardingEvent {
  const P2pOnboardingEvent();
}

/// Called when the user lands on the Apply screen to reset state.
class P2pOnboardingStarted extends P2pOnboardingEvent {
  const P2pOnboardingStarted();
}

/// Carries the courier profile form data from the onboarding screen
/// (service radius, accepted categories, bio). Advances to the identity step.
class P2pOnboardingProfileSubmitted extends P2pOnboardingEvent {
  final Map<String, dynamic> data;
  const P2pOnboardingProfileSubmitted(this.data);
}

/// Carries identity form data (legal name, DOB, nationality, address, ID type).
class P2pOnboardingIdentitySubmitted extends P2pOnboardingEvent {
  final Map<String, dynamic> data;
  const P2pOnboardingIdentitySubmitted(this.data);
}

/// Carries document paths (passport, visa, flight itinerary).
class P2pOnboardingDocumentsSubmitted extends P2pOnboardingEvent {
  final Map<String, dynamic> data;
  const P2pOnboardingDocumentsSubmitted(this.data);
}

/// Carries route data (origin, destination, departure date, capacity, categories).
class P2pOnboardingRouteSubmitted extends P2pOnboardingEvent {
  final Map<String, dynamic> data;
  const P2pOnboardingRouteSubmitted(this.data);
}

/// Carries compliance acknowledgements (all checkbox flags).
class P2pOnboardingComplianceSubmitted extends P2pOnboardingEvent {
  final Map<String, dynamic> data;
  const P2pOnboardingComplianceSubmitted(this.data);
}

/// User taps final "Submit Application" on the review screen.
class P2pOnboardingConfirmSubmit extends P2pOnboardingEvent {
  const P2pOnboardingConfirmSubmit();
}

/// Resets the bloc back to step 0 (e.g. on success or back to marketplace).
class P2pOnboardingReset extends P2pOnboardingEvent {
  const P2pOnboardingReset();
}
