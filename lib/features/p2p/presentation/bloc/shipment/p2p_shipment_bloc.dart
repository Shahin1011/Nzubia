import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/data/services/p2p_payment_tracker.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_offer.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';

part 'p2p_shipment_event.dart';
part 'p2p_shipment_state.dart';

class P2pShipmentBloc extends Bloc<P2pShipmentEvent, P2pShipmentState> {
  final P2pShipmentRepository _repository;

  P2pShipmentBloc({required P2pShipmentRepository repository})
      : _repository = repository,
        super(const P2pShipmentState()) {
    on<P2pShipmentListRequested>(_onListRequested);
    on<P2pShipmentDetailRequested>(_onDetailRequested);
    on<P2pShipmentCreateRequested>(_onCreateRequested);
    on<P2pShipmentMatchesRequested>(_onMatchesRequested);
    on<P2pShipmentOffersRequested>(_onOffersRequested);
    on<P2pShipmentStatusChanged>(_onStatusChanged);
    on<P2pOfferAccepted>(_onOfferAccepted);
    on<P2pOfferRejected>(_onOfferRejected);
    on<P2pShipmentReserveRequested>(_onReserveRequested);
    on<P2pShipmentHandoffRequested>(_onHandoffRequested);
    on<P2pShipmentDeliveryConfirmed>(_onDeliveryConfirmed);
  }

  Future<void> _onListRequested(
    P2pShipmentListRequested event,
    Emitter<P2pShipmentState> emit,
  ) async {
    emit(state.copyWith(status: P2pShipmentStatus.loading));
    try {
      final requests = await _repository.listRequests();
      final openRequests = requests
          .where((request) => request.status == ShipmentRequestStatus.open)
          .toList(growable: false);
      final counts = <String, int>{};
      if (openRequests.isNotEmpty) {
        final results = await Future.wait(
          openRequests.map((request) async {
            try {
              final offers = await _repository.listOffers(request.id);
              final activeCount = offers.where((offer) {
                return offer.status == OfferStatus.proposed;
              }).length;
              return MapEntry(request.id, activeCount);
            } catch (_) {
              return MapEntry(request.id, 0);
            }
          }),
        );
        counts.addEntries(results);
      }
      emit(state.copyWith(
        status: P2pShipmentStatus.success,
        requests: requests,
        courierRequestCounts: counts,
      ));
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onDetailRequested(
    P2pShipmentDetailRequested event,
    Emitter<P2pShipmentState> emit,
  ) async {
    emit(state.copyWith(status: P2pShipmentStatus.loading));
    try {
      final request = await _repository.getRequest(event.requestId);
      // Best-effort: fetch offers and sent courier requests alongside the detail.
      List<P2pOffer> offers = const [];
      List<P2pCourierRequest> courierRequests = const [];
      try {
        offers = await _repository.listOffers(event.requestId);
      } catch (_) {}
      try {
        courierRequests =
            await _repository.listCourierRequests(event.requestId);
      } catch (_) {}
      emit(state.copyWith(
        status: P2pShipmentStatus.success,
        selectedRequest: request,
        offers: offers,
        courierRequests: courierRequests,
      ));
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onCreateRequested(
    P2pShipmentCreateRequested event,
    Emitter<P2pShipmentState> emit,
  ) async {
    emit(state.copyWith(status: P2pShipmentStatus.loading));
    try {
      final request = await _repository.createRequest(event.requestData);
      // DRAFT → OPEN so it becomes visible to couriers.
      P2pShipmentRequest opened = request;
      try {
        opened = await _repository.updateStatus(
          request.id,
          ShipmentRequestStatus.open,
        );
      } catch (_) {
        opened = request;
      }
      // Trigger matching algorithm — scores routes and notifies top couriers.
      try {
        await _repository.matchRequest(opened.id);
      } catch (_) {}
      emit(state.copyWith(
        status: P2pShipmentStatus.success,
        requests: [opened, ...state.requests],
        selectedRequest: opened,
      ));
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onMatchesRequested(
    P2pShipmentMatchesRequested event,
    Emitter<P2pShipmentState> emit,
  ) async {
    emit(state.copyWith(status: P2pShipmentStatus.loading));
    try {
      final matches = await _repository.matchRequest(event.requestId);
      emit(state.copyWith(
        status: P2pShipmentStatus.success,
        matches: matches,
      ));
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onOffersRequested(
    P2pShipmentOffersRequested event,
    Emitter<P2pShipmentState> emit,
  ) async {
    try {
      final offers = await _repository.listOffers(event.requestId);
      emit(state.copyWith(
        status: P2pShipmentStatus.success,
        offers: offers,
      ));
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onStatusChanged(
    P2pShipmentStatusChanged event,
    Emitter<P2pShipmentState> emit,
  ) async {
    try {
      final updated = await _repository.updateStatus(
        event.requestId,
        event.newStatus,
      );
      _replaceSelected(emit, updated);
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onOfferAccepted(
    P2pOfferAccepted event,
    Emitter<P2pShipmentState> emit,
  ) async {
    emit(state.copyWith(status: P2pShipmentStatus.loading));
    try {
      final accepted = await _repository.acceptOffer(event.offerId);
      // Persist pending payment so re-entry can route back to payment screen.
      if (event.shipmentId != null &&
          accepted.offerAmountUsd != null &&
          accepted.offerAmountUsd! > 0) {
        P2pPaymentTracker.savePendingPayment(
          event.shipmentId!,
          accepted.offerAmountUsd!,
          clientSecret: accepted.clientSecret,
          offerId: accepted.id,
        );
      }
      P2pShipmentState next;
      if (event.shipmentId != null) {
        final refreshed = await _repository.getRequest(event.shipmentId!);
        final updatedList = state.requests
            .map((r) => r.id == refreshed.id ? refreshed : r)
            .toList(growable: false);
        next = state.copyWith(
          status: P2pShipmentStatus.success,
          selectedRequest: refreshed,
          requests: updatedList,
          pendingPaymentClientSecret: accepted.clientSecret,
          pendingPaymentAmountUsd: accepted.offerAmountUsd,
          pendingPaymentOfferId: accepted.id,
        );
      } else {
        next = state.copyWith(
          status: P2pShipmentStatus.success,
          pendingPaymentClientSecret: accepted.clientSecret,
          pendingPaymentAmountUsd: accepted.offerAmountUsd,
          pendingPaymentOfferId: accepted.id,
        );
      }
      emit(next);
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onOfferRejected(
    P2pOfferRejected event,
    Emitter<P2pShipmentState> emit,
  ) async {
    try {
      await _repository.rejectOffer(event.offerId);
      if (event.shipmentId != null) {
        try {
          final offers = await _repository.listOffers(event.shipmentId!);
          emit(state.copyWith(
            status: P2pShipmentStatus.success,
            offers: offers,
          ));
        } catch (_) {
          emit(state.copyWith(status: P2pShipmentStatus.success));
        }
      } else {
        emit(state.copyWith(status: P2pShipmentStatus.success));
      }
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onReserveRequested(
    P2pShipmentReserveRequested event,
    Emitter<P2pShipmentState> emit,
  ) async {
    try {
      final updated = await _repository.reserveShipment(event.requestId);
      _replaceSelected(emit, updated);
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onHandoffRequested(
    P2pShipmentHandoffRequested event,
    Emitter<P2pShipmentState> emit,
  ) async {
    try {
      final updated = await _repository.recordHandoff(event.requestId);
      _replaceSelected(emit, updated);
    } catch (e) {
      emit(_fail(e));
    }
  }

  Future<void> _onDeliveryConfirmed(
    P2pShipmentDeliveryConfirmed event,
    Emitter<P2pShipmentState> emit,
  ) async {
    try {
      final updated = await _repository.completeShipment(event.requestId);
      _replaceSelected(emit, updated);
    } catch (e) {
      emit(_fail(e));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _replaceSelected(
    Emitter<P2pShipmentState> emit,
    P2pShipmentRequest updated,
  ) {
    final updatedList = state.requests
        .map((r) => r.id == updated.id ? updated : r)
        .toList(growable: false);
    emit(state.copyWith(
      status: P2pShipmentStatus.success,
      selectedRequest: updated,
      requests: updatedList,
    ));
  }

  P2pShipmentState _fail(Object e) => state.copyWith(
        status: P2pShipmentStatus.failure,
        errorMessage: e.toString(),
      );
}
