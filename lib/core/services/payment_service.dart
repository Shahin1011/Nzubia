abstract class PaymentService {
  /// Initialise the Stripe payment sheet by creating a new PaymentIntent
  /// on the backend for the given amount and currency.
  Future<void> initPaymentSheet({required String amount, required String currency});

  /// Initialise the Stripe payment sheet using an existing PaymentIntent
  /// client_secret returned by the backend (e.g. the P2P offer-acceptance flow).
  Future<void> initPaymentSheetWithClientSecret(String clientSecret);

  /// Present the initialised payment sheet to the user.
  Future<void> presentPaymentSheet();
}
