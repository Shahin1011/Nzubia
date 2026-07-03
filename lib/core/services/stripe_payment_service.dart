import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:customer_nzubia_global/core/services/payment_service.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';

class StripePaymentService implements PaymentService {
  final DioClient _dioClient;

  StripePaymentService(this._dioClient);

  @override
  Future<void> initPaymentSheet({required String amount, required String currency, required String quoteId}) async {
    try {
      final clientSecret = await _createPaymentIntent(amount, currency, quoteId);
      
      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Nzubia',
          style: ThemeMode.light,
          returnURL: 'nzubia://payment-success', // Deep Link for 3DS redirect
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize payment sheet: $e');
    }
  }

  /// Use this when the PaymentIntent was already created server-side and you
  /// have its client_secret (e.g. P2P offer acceptance flow).
  @override
  Future<void> initPaymentSheetWithClientSecret(String clientSecret) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Nzubia',
          style: ThemeMode.light,
          returnURL: 'nzubia://payment-success',
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize payment sheet: $e');
    }
  }

  @override
  Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      final code = e.error.code.toString();
      final msg = e.error.localizedMessage ?? e.error.message ?? code;
      // Propagate a message that _friendlyError can classify.
      throw Exception('Payment failed: $msg (code: $code)');
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  Future<String> _createPaymentIntent(String amount, String currency, String quoteId) async {
    try {
      final response = await _dioClient.dio.post(
        '/payments/create-intent',
        data: {
          'amount': (double.parse(amount) * 100).toInt(),
          'currency': currency,
          'quoteId': quoteId,
        },
      );
      return response.data['clientSecret'];
    } catch (e) {
      throw Exception('Backend Payment Intent failed: $e');
    }
  }
}
