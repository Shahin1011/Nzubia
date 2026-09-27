class ApiConstants {
  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://deaf-forget-symptoms-incorporate.trycloudflare.com/api/v1',
  );

  static String get stripePublishableKey => const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    // No hardcoded fallback — pass via --dart-define=STRIPE_PUBLISHABLE_KEY=pk_...
    defaultValue: '',
  );

  // Pass via --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy...
  // For Android the key is also injected via manifestPlaceholders in build.gradle.
  static const String googleMapApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static String get socketUrl {
    const override = String.fromEnvironment('SOCKET_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return override;
    }

    final apiBaseUrl = baseUrl.replaceAll(RegExp(r'/api/v\d+/?$'), '');
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    }
    if (apiBaseUrl.startsWith('http://')) {
      return apiBaseUrl.replaceFirst('http://', 'ws://');
    }
    return 'wss://api.nzubia.com';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String profile = '/users/profile';
  static const String agentOnboarding = '/users/agent/onboarding';

  static const String deleteAccount = '/users/me';
  static const String changePassword = '/auth/change-password';
  static const String stripeOnboarding = '/users/stripe/onboarding';
  static const String stripeStatus = '/users/stripe/status';

  // Shipments
  static const String shipments = '/shipments';
  static const String quotes = '/quotes';
  static const String documents = '/documents';
  static const String fileUpload = '/files/upload';

  // Payments
  static const String createPaymentIntent = '/payments/create-intent';

  // Chat
  static const String chatNamespace = '/chat';

  // ─── P2P paths (canonical contract — must match backend) ────────────────────
  // Couriers
  static const String p2pCouriers = '/p2p/couriers';
  static const String p2pCourierMe = '/p2p/couriers/me';
  static const String p2pCourierMeSubmit = '/p2p/couriers/me/submit';
  static const String p2pCourierMeKyc = '/p2p/couriers/me/kyc';
  static const String p2pCourierMeAvailability = '/p2p/couriers/me/availability';
  static const String p2pCourierMeStatus = '/p2p/couriers/me/status';
  static const String p2pCourierMeStripeConnect = '/p2p/couriers/me/stripe/connect';
  static const String p2pCourierMeStripeStatus = '/p2p/couriers/me/stripe/status';
  static const String p2pCourierMeStripeDashboard = '/p2p/couriers/me/stripe/dashboard-link';
  static String p2pCourierById(String id) => '/p2p/couriers/$id';
  static String p2pCourierReputation(String id) => '/p2p/couriers/$id/reputation';

  // Routes
  static const String p2pRoutes = '/p2p/routes';
  static const String p2pRoutesFeed = '/p2p/routes/feed';
  static const String p2pRoutesMine = '/p2p/routes/mine';
  static String p2pRouteById(String id) => '/p2p/routes/$id';
  static String p2pRouteStatus(String id) => '/p2p/routes/$id/status';

  // Shipments (P2P)
  static const String p2pShipments = '/p2p/shipments';
  static String p2pShipmentById(String id) => '/p2p/shipments/$id';
  static String p2pShipmentStatus(String id) => '/p2p/shipments/$id/status';
  static String p2pShipmentMatch(String id) => '/p2p/shipments/$id/match';
  static String p2pShipmentReserve(String id) => '/p2p/shipments/$id/reserve';
  static String p2pShipmentHandoff(String id) => '/p2p/shipments/$id/handoff';
  static String p2pShipmentPickup(String id) => '/p2p/shipments/$id/pickup';
  static String p2pShipmentDeliver(String id) => '/p2p/shipments/$id/deliver';
  static String p2pShipmentComplete(String id) => '/p2p/shipments/$id/complete';
  static String p2pShipmentDispute(String id) => '/p2p/shipments/$id/dispute';
  static String p2pShipmentOffers(String id) => '/p2p/shipments/$id/offers';

  // Offers (nested under shipments controller)
  static String p2pOfferAccept(String offerId) =>
      '/p2p/shipments/offers/$offerId/accept';
  static String p2pOfferRefreshPayment(String offerId) =>
      '/p2p/shipments/offers/$offerId/refresh-payment';
  static String p2pOfferReject(String offerId) =>
      '/p2p/shipments/offers/$offerId/reject';

  // Courier requests (seeker → specific courier)
  static String p2pShipmentCourierRequests(String shipmentId) =>
      '/p2p/shipments/$shipmentId/courier-requests';

  // Courier incoming requests (courier accepts/declines seeker's direct requests)
  static const String p2pCourierMeRequests = '/p2p/couriers/me/requests';

  // Courier browse: OPEN shipments within 50 miles of courier's home location
  static const String p2pCourierMeNearbyShipments = '/p2p/couriers/me/nearby-shipments';

  // Courier dispute queue: DISPUTED shipments where this courier is the assigned carrier
  static const String p2pCourierMeDisputes = '/p2p/couriers/me/disputes';
  static String p2pCourierRequestAccept(String id) =>
      '/p2p/couriers/me/requests/$id/accept';
  static String p2pCourierRequestDecline(String id) =>
      '/p2p/couriers/me/requests/$id/decline';

  // Compliance
  static const String p2pComplianceRules = '/p2p/compliance/rules';
  static const String p2pComplianceRestricted = '/p2p/compliance/restricted';
  static String p2pComplianceWaiver(String shipmentId) =>
      '/p2p/compliance/waiver/$shipmentId';
  static String p2pComplianceWaiverAccept(String shipmentId) =>
      '/p2p/compliance/waiver/$shipmentId/accept';
  static String p2pComplianceStatus(String shipmentId) =>
      '/p2p/compliance/status/$shipmentId';

  // Reviews
  static const String p2pReviews = '/p2p/reviews';
  static String p2pReviewsForCourier(String courierId) =>
      '/p2p/reviews/courier/$courierId';

  // Optional dev access token passed via --dart-define=DEV_ACCESS_TOKEN=<token>
  static String get devAccessToken => const String.fromEnvironment('DEV_ACCESS_TOKEN', defaultValue: '');
}
