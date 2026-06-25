import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_offer.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';

abstract class P2pShipmentRepository {
  /// Seeker creates a new shipment request (DRAFT state).
  Future<P2pShipmentRequest> createRequest(Map<String, dynamic> requestData);

  /// Lists the authenticated seeker's own requests.
  Future<List<P2pShipmentRequest>> listRequests();

  /// Returns a single shipment request by ID.
  Future<P2pShipmentRequest> getRequest(String requestId);

  /// Updates a DRAFT shipment request.
  Future<P2pShipmentRequest> updateRequest(
    String requestId,
    Map<String, dynamic> updates,
  );

  /// Advances the shipment status (enforces server-side state machine).
  Future<P2pShipmentRequest> updateStatus(
    String requestId,
    ShipmentRequestStatus newStatus,
  );

  /// Returns the top-5 matching routes for a shipment with composite scores.
  Future<List<P2pRouteFeedItem>> matchRequest(String requestId);

  /// Lists offers on a shipment (seeker sees all, courier sees their own).
  Future<List<P2pOffer>> listOffers(String requestId);

  /// Courier creates an offer on a shipment request.
  Future<P2pOffer> createOffer(String requestId, Map<String, dynamic> offerData);

  /// Seeker accepts a specific offer.
  Future<P2pOffer> acceptOffer(String offerId);

  /// Seeker rejects a specific offer.
  Future<P2pOffer> rejectOffer(String offerId);

  /// Marks the shipment as RESERVED (after acceptance).
  Future<P2pShipmentRequest> reserveShipment(String requestId);

  /// Records the handoff — moves to HANDOFF_PENDING and opens a chat thread.
  Future<P2pShipmentRequest> recordHandoff(String requestId);

  /// Courier confirms pickup with the seeker's OTP and proof photos — moves to IN_TRANSIT.
  Future<P2pShipmentRequest> recordPickup(
    String shipmentId, {
    required String pickupConfirmationCode,
    required List<String> proofPhotoUrls,
  });

  /// Courier confirms delivery with proof photos — moves to DELIVERED.
  Future<P2pShipmentRequest> confirmDelivery(
    String requestId, {
    List<String>? proofPhotoUrls,
  });

  /// Seeker sends a direct booking request to a specific courier route.
  Future<void> sendCourierRequest(
    String shipmentId,
    String routeId, {
    String? message,
  });

  /// Lists the courier requests the seeker has sent for a specific shipment.
  Future<List<P2pCourierRequest>> listCourierRequests(String shipmentId);

  /// Returns shipments where the authenticated courier is the assigned carrier.
  /// Filters to active states: HANDOFF_PENDING, IN_TRANSIT, DELIVERED.
  Future<List<P2pShipmentRequest>> listAssignedShipments();

  /// Returns shipments in DISPUTED status where this courier is the assigned carrier.
  Future<List<P2pShipmentRequest>> listMyDisputedShipments();

  /// Returns OPEN shipment requests within 50 miles of the courier's home location.
  Future<List<P2pShipmentRequest>> fetchNearbyShipments();

  /// Marks a DELIVERED shipment as COMPLETED (seeker confirms receipt).
  Future<P2pShipmentRequest> completeShipment(String shipmentId);

  /// Opens a dispute on a DELIVERED shipment.
  Future<P2pShipmentRequest> raiseDispute(
    String shipmentId, {
    required String reason,
    List<String>? evidenceUrls,
  });
}
