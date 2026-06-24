part of 'p2p_shipment_bloc.dart';

enum P2pShipmentStatus { initial, loading, success, failure }

class P2pShipmentState {
  final P2pShipmentStatus status;
  final List<P2pShipmentRequest> requests;
  final P2pShipmentRequest? selectedRequest;
  final List<P2pOffer> offers;
  final List<P2pRouteFeedItem> matches;
  final Map<String, int> courierRequestCounts;

  /// Courier requests the seeker sent for the currently selected shipment.
  final List<P2pCourierRequest> courierRequests;
  final String? errorMessage;
  /// Stripe PaymentIntent client_secret emitted once after a successful offer
  /// acceptance. The screen must consume it (navigate to payment) and clear it.
  final String? pendingPaymentClientSecret;
  /// The accepted offer amount in USD, carried alongside the client_secret.
  final double? pendingPaymentAmountUsd;
  /// The accepted offer ID, needed to refresh a stale PaymentIntent.
  final String? pendingPaymentOfferId;

  const P2pShipmentState({
    this.status = P2pShipmentStatus.initial,
    this.requests = const [],
    this.selectedRequest,
    this.offers = const [],
    this.matches = const [],
    this.courierRequestCounts = const {},
    this.courierRequests = const [],
    this.errorMessage,
    this.pendingPaymentClientSecret,
    this.pendingPaymentAmountUsd,
    this.pendingPaymentOfferId,
  });

  P2pShipmentState copyWith({
    P2pShipmentStatus? status,
    List<P2pShipmentRequest>? requests,
    P2pShipmentRequest? selectedRequest,
    List<P2pOffer>? offers,
    List<P2pRouteFeedItem>? matches,
    Map<String, int>? courierRequestCounts,
    List<P2pCourierRequest>? courierRequests,
    String? errorMessage,
    String? pendingPaymentClientSecret,
    double? pendingPaymentAmountUsd,
    String? pendingPaymentOfferId,
    bool clearPendingPayment = false,
  }) {
    return P2pShipmentState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      selectedRequest: selectedRequest ?? this.selectedRequest,
      offers: offers ?? this.offers,
      matches: matches ?? this.matches,
      courierRequestCounts: courierRequestCounts ?? this.courierRequestCounts,
      courierRequests: courierRequests ?? this.courierRequests,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingPaymentClientSecret: clearPendingPayment
          ? null
          : (pendingPaymentClientSecret ?? this.pendingPaymentClientSecret),
      pendingPaymentAmountUsd: clearPendingPayment
          ? null
          : (pendingPaymentAmountUsd ?? this.pendingPaymentAmountUsd),
      pendingPaymentOfferId: clearPendingPayment
          ? null
          : (pendingPaymentOfferId ?? this.pendingPaymentOfferId),
    );
  }
}
