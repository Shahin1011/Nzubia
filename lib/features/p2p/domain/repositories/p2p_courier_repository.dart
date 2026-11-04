import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';

/// Talks to the `/p2p/couriers` namespace. All write paths target the canonical
/// `/p2p/couriers/me*` routes; the public list/profile/reputation routes are
/// available to any authenticated user.
abstract class P2pCourierRepository {
  /// Returns the authenticated user's courier profile, or null if they have
  /// not applied yet.
  Future<P2pCourierProfile?> getMyProfile();

  /// Submits the courier application (creates the DRAFT profile).
  Future<P2pCourierProfile> applyAsCourier(Map<String, dynamic> applicationData);

  /// Transitions the courier profile from DRAFT → PENDING_REVIEW so the admin
  /// can see it in the verification queue.
  Future<P2pCourierProfile> submitForReview();

  /// Uploads a single file (multipart/form-data) and returns the GCS URL.
  Future<String> uploadDocument(String localPath, String folder);

  /// Saves KYC identity data and document URLs to the courier profile.
  Future<void> submitKyc({
    required Map<String, dynamic> identity,
    required List<Map<String, dynamic>> documentUrls,
  });

  /// Performs an automated real-time background check on the courier identity.
  /// Returns a map containing {success: bool, status: String, message: String, user: Map?}.
  Future<Map<String, dynamic>> verifyBackgroundCheck({
    String? firstName,
    String? lastName,
    String? dob,
    String? state,
    Map<String, dynamic>? documentUrls,
  });

  /// Updates the courier profile (radius, accepted categories, home location).
  Future<P2pCourierProfile> updateProfile(Map<String, dynamic> updates);

  /// Toggles courier availability on/off. Only valid in APPROVED/ACTIVE.
  Future<P2pCourierProfile> setAvailability({required bool isActive});

  /// Returns the authenticated courier's verification + availability snapshot.
  Future<P2pCourierStatus> getMyStatus();

  /// Lists public courier profiles, optionally filtered by destination.
  Future<List<P2pCourierProfile>> listPublicCouriers({
    String? destinationCountry,
    String? destinationCity,
    int limit = 20,
  });

  /// Returns a public courier profile by ID.
  Future<P2pCourierProfile> getPublicProfile(String courierId);

  /// Returns aggregated reputation (average rating + recent reviews).
  Future<P2pCourierReputation> getReputation(String courierId);

  /// Lists incoming direct requests from seekers targeting this courier's routes.
  Future<List<P2pCourierRequest>> listIncomingRequests();

  /// Courier accepts a seeker's direct request. Optionally set a counter-offer amount.
  Future<P2pCourierRequest> acceptCourierRequest(
    String requestId, {
    double? offerAmountUsd,
    String? message,
  });

  /// Courier declines a seeker's direct request.
  Future<P2pCourierRequest> declineCourierRequest(
    String requestId, {
    String? reason,
  });

  // ── Stripe Connect ──────────────────────────────────────────────────────────

  /// Creates (or reuses) a Stripe Express account for this courier and returns
  /// the `stripeConnectId` and a one-time `onboardingUrl` to open in a browser.
  Future<P2pStripeConnectResult> initiateStripeConnect({
    String? country,
    String? returnUrl,
    String? refreshUrl,
  });

  /// Returns the current Stripe Connect onboarding state.
  Future<P2pStripeConnectStatus> getStripeConnectStatus();

  /// Returns a short-lived Stripe Express Dashboard URL.
  Future<String> getStripeDashboardLink();
}

class P2pStripeConnectResult {
  final String stripeConnectId;
  final String onboardingUrl;
  final String? message;
  final bool success;

  const P2pStripeConnectResult({
    required this.stripeConnectId,
    required this.onboardingUrl,
    this.message,
    this.success = true,
  });

  factory P2pStripeConnectResult.fromJson(Map<String, dynamic> json) {
    return P2pStripeConnectResult(
      stripeConnectId:
          (json['accountId'] ?? json['stripeConnectId'] ?? '').toString(),
      onboardingUrl: (json['onboardingUrl'] ?? json['url'] ?? '').toString(),
      message: json['message'] as String?,
      success: json['success'] as bool? ?? true,
    );
  }
}

class P2pStripeConnectStatus {
  final bool hasStripeAccount;
  final bool payoutsEnabled;
  final bool chargesEnabled;
  final bool detailsSubmitted;
  final String? accountId;
  final String? bankName;
  final String? last4;
  final List<Map<String, dynamic>> externalAccounts;

  const P2pStripeConnectStatus({
    required this.hasStripeAccount,
    required this.payoutsEnabled,
    this.chargesEnabled = false,
    this.detailsSubmitted = false,
    this.accountId,
    this.bankName,
    this.last4,
    this.externalAccounts = const [],
  });

  bool get connected => hasStripeAccount;
  bool get payoutReady => payoutsEnabled;

  factory P2pStripeConnectStatus.fromJson(Map<String, dynamic> json) {
    final hasStripe = json['has_stripe_account'] as bool? ??
        json['hasStripeAccount'] as bool? ??
        json['connected'] as bool? ??
        false;
    final payouts = json['payouts_enabled'] as bool? ??
        json['payoutsEnabled'] as bool? ??
        json['payoutReady'] as bool? ??
        false;
    final charges = json['charges_enabled'] as bool? ??
        json['chargesEnabled'] as bool? ??
        false;
    final submitted = json['details_submitted'] as bool? ??
        json['detailsSubmitted'] as bool? ??
        false;
    final acctId =
        json['accountId'] as String? ?? json['account_id'] as String?;

    String? bank;
    String? l4;
    final extAccts =
        (json['external_accounts'] ?? json['externalAccounts']) as List?;
    final accountsList = <Map<String, dynamic>>[];
    if (extAccts != null && extAccts.isNotEmpty) {
      for (final item in extAccts) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          accountsList.add(m);
          bank ??= m['bank_name'] as String? ?? m['bankName'] as String?;
          l4 ??= m['last4'] as String?;
        }
      }
    }

    return P2pStripeConnectStatus(
      hasStripeAccount: hasStripe,
      payoutsEnabled: payouts,
      chargesEnabled: charges,
      detailsSubmitted: submitted,
      accountId: acctId,
      bankName: bank,
      last4: l4,
      externalAccounts: accountsList,
    );
  }
}
