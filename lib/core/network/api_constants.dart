class ApiConstants {
  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://deaf-forget-symptoms-incorporate.trycloudflare.com/api/v1',
  );
  
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  
  // Users
  static const String users = '/users';
  static const String profile = '/users/profile';
  
  // Shipments
  static const String shipments = '/shipments';
  
  // Quotes
  static const String quotes = '/quotes';
  
  // Payouts
  static const String createRecipient = '/users/payout/create-recipient';
  static const String onboardingLink = '/users/payout/onboarding-link';
  static const String payoutStatus = '/users/payout/status';
  static const String payoutHistory = '/users/payout/history';
}
