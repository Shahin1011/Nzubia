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
}
