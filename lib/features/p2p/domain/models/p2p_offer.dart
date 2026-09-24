import 'package:equatable/equatable.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';

class P2pOffer extends Equatable {
  final String id;
  final String shipmentRequestId;
  final String routeId;
  final P2pRoute? route;
  final double? offerAmountUsd;
  final OfferStatus status;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? expiresAt;
  final String? paymentReference;
  final String? paymentStatus;
  /// Only populated immediately after offer acceptance — holds the Stripe
  /// PaymentIntent client_secret needed to complete the payment on the client.
  final String? clientSecret;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const P2pOffer({
    required this.id,
    required this.shipmentRequestId,
    required this.routeId,
    this.route,
    this.offerAmountUsd,
    required this.status,
    this.acceptedAt,
    this.rejectedAt,
    this.expiresAt,
    this.paymentReference,
    this.paymentStatus,
    this.clientSecret,
    this.createdAt,
    this.updatedAt,
  });

  factory P2pOffer.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.parse(v as String);

    return P2pOffer(
      id: json['id'] as String,
      shipmentRequestId: json['shipment_request_id'] as String,
      routeId: json['route_id'] as String,
      route: json['route'] is Map<String, dynamic>
          ? P2pRoute.fromJson(json['route'] as Map<String, dynamic>)
          : null,
      offerAmountUsd: json['offer_amount_usd'] != null 
          ? double.tryParse(json['offer_amount_usd'].toString()) 
          : null,
      status: OfferStatus.fromJson(json['status'] as String?),
      acceptedAt: parseDate(json['accepted_at']),
      rejectedAt: parseDate(json['rejected_at']),
      expiresAt: parseDate(json['expires_at']),
      paymentReference: json['payment_reference'] as String?,
      paymentStatus: json['payment_status'] as String?,
      clientSecret: json['client_secret'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        shipmentRequestId,
        routeId,
        route,
        offerAmountUsd,
        status,
        acceptedAt,
        rejectedAt,
        expiresAt,
        paymentReference,
        paymentStatus,
        clientSecret,
        createdAt,
        updatedAt,
      ];
}
