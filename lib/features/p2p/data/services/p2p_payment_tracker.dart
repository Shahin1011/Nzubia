import 'package:hive/hive.dart';

/// Lightweight local cache that persists P2P payment state across app restarts.
///
/// This is NOT the source of truth — the backend's offer.paymentStatus is.
/// The tracker is used only for routing: if the app is killed mid-payment and
/// the user returns, we can route them back to the payment screen without an
/// extra API round-trip.
///
/// Lifecycle:
///   1. savePendingPayment()   — called when offer is accepted (BLoC)
///   2. markPaymentComplete()  — called when Stripe payment sheet succeeds
///   3. hasCompletedPayment()  — checked on re-entry to skip payment screen
class P2pPaymentTracker {
  static Box get _box => Hive.box('settings');

  static const _donePrefix = 'p2p_pay_done_';
  static const _amountPrefix = 'p2p_pay_amount_';
  static const _secretPrefix = 'p2p_pay_secret_';

  static void savePendingPayment(
    String shipmentId,
    double amountUsd, {
    String? clientSecret,
  }) {
    _box.put('$_amountPrefix$shipmentId', amountUsd);
    _box.put('$_donePrefix$shipmentId', false);
    if (clientSecret != null) {
      _box.put('$_secretPrefix$shipmentId', clientSecret);
    }
  }

  static String? getPendingClientSecret(String shipmentId) {
    final val = _box.get('$_secretPrefix$shipmentId');
    return val is String ? val : null;
  }

  static bool hasCompletedPayment(String shipmentId) =>
      _box.get('$_donePrefix$shipmentId', defaultValue: false) as bool;

  static void markPaymentComplete(String shipmentId) {
    _box.put('$_donePrefix$shipmentId', true);
    _box.delete('$_amountPrefix$shipmentId');
    _box.delete('$_secretPrefix$shipmentId');
  }

  /// Returns the pending amount, or null if payment was already completed or
  /// no offer has been accepted yet for this shipment.
  static double? getPendingAmount(String shipmentId) {
    if (hasCompletedPayment(shipmentId)) return null;
    final val = _box.get('$_amountPrefix$shipmentId');
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return null;
  }

  static bool hasPaymentPending(String shipmentId) =>
      getPendingAmount(shipmentId) != null;
}
