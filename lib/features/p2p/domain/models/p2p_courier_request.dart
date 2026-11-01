import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';

class P2pCourierRequest {
  final String id;
  final String shipmentRequestId;
  final String routeId;
  final P2pRoute? route;
  final String seekerUserId;
  final String? seekerName;
  final String? seekerEmail;
  final String? message;
  final CourierRequestStatus status;
  final String? declineReason;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const P2pCourierRequest({
    required this.id,
    required this.shipmentRequestId,
    required this.routeId,
    this.route,
    required this.seekerUserId,
    this.seekerName,
    this.seekerEmail,
    this.message,
    required this.status,
    this.declineReason,
    this.respondedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory P2pCourierRequest.fromJson(Map<String, dynamic> json) {
    final seeker = (json['seeker'] is Map<String, dynamic>)
        ? json['seeker'] as Map<String, dynamic>
        : null;
    return P2pCourierRequest(
      id: (json['id'] ?? '').toString(),
      shipmentRequestId: (json['shipment_request_id'] ?? json['shipmentRequestId'] ?? '').toString(),
      routeId: (json['route_id'] ?? json['routeId'] ?? '').toString(),
      route: json['route'] is Map<String, dynamic>
          ? P2pRoute.fromJson(json['route'] as Map<String, dynamic>)
          : null,
      seekerUserId: (json['seeker_user_id'] ?? json['seekerUserId'] ?? '').toString(),
      seekerName: seeker?['name'] as String? ??
          seeker?['full_name'] as String? ??
          seeker?['first_name'] as String?,
      seekerEmail: seeker?['email'] as String?,
      message: json['message'] as String?,
      status: CourierRequestStatus.fromJson(json['status'] as String?),
      declineReason: (json['decline_reason'] ?? json['declineReason']) as String?,
      respondedAt: json['responded_at'] != null || json['respondedAt'] != null
          ? DateTime.tryParse((json['responded_at'] ?? json['respondedAt']).toString())
          : null,
      expiresAt: json['expires_at'] != null || json['expiresAt'] != null
          ? DateTime.tryParse((json['expires_at'] ?? json['expiresAt']).toString())
          : null,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? (DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
