import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_route.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_shipment_request.dart';
import 'package:customer_nzubia_global/features/p2p/domain/enums/p2p_enums.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';

part 'courier_dashboard_event.dart';
part 'courier_dashboard_state.dart';

class CourierDashboardBloc
    extends Bloc<CourierDashboardEvent, CourierDashboardState> {
  final P2pCourierRepository _courierRepo;
  final P2pRouteRepository _routeRepo;
  final P2pShipmentRepository _shipmentRepo;

  CourierDashboardBloc({
    required P2pCourierRepository courierRepository,
    required P2pRouteRepository routeRepository,
    required P2pShipmentRepository shipmentRepository,
  })  : _courierRepo = courierRepository,
        _routeRepo = routeRepository,
        _shipmentRepo = shipmentRepository,
        super(const CourierDashboardState()) {
    on<CourierDashboardLoadRequested>(_onLoadRequested);
    on<CourierDashboardAvailabilityToggled>(_onAvailabilityToggled);
    on<CourierDashboardRoutePublishRequested>(_onRoutePublishRequested);
    on<CourierDashboardRequestAccepted>(_onRequestAccepted);
    on<CourierDashboardRequestDeclined>(_onRequestDeclined);
    on<CourierDashboardRouteArchiveRequested>(_onRouteArchiveRequested);
    on<CourierDashboardLocationUpdated>(_onLocationUpdated);
    on<CourierDashboardSubmitForReviewRequested>(_onSubmitForReviewRequested);
  }

  Future<void> _onLoadRequested(
    CourierDashboardLoadRequested event,
    Emitter<CourierDashboardState> emit,
  ) async {
    emit(state.copyWith(status: CourierDashboardStatus.loading));
    try {
      final profile = await _courierRepo.getMyProfile();
      if (profile == null) {
        emit(state.copyWith(
          status: CourierDashboardStatus.failure,
          errorMessage: 'No courier profile found. Please apply first.',
        ));
        return;
      }

      // Load courier-owned routes. Pick the next PUBLISHED route by departure
      // as the "active" route for the dashboard hero card.
      List<P2pRoute> myRoutes = const [];
      try {
        myRoutes = await _routeRepo.listMyRoutes();
      } catch (_) {
        // Non-fatal — dashboard still works without routes.
      }
      P2pRoute? activeRoute;
      for (final r in myRoutes) {
        if (r.status == RouteStatus.published) {
          activeRoute = r;
          break;
        }
      }

      List<P2pCourierRequest> pendingRequests = const [];
      try {
        final all = await _courierRepo.listIncomingRequests();
        pendingRequests = all
            .where((r) => r.status == CourierRequestStatus.pending)
            .toList();
      } catch (_) {
        // Non-fatal — dashboard still works without requests.
      }

      List<P2pShipmentRequest> activeShipments = const [];
      try {
        activeShipments = await _shipmentRepo.listAssignedShipments();
      } catch (_) {
        // Non-fatal — dashboard still works without active shipments.
      }

      emit(state.copyWith(
        status: CourierDashboardStatus.success,
        profile: profile,
        myRoutes: myRoutes,
        activeRoute: activeRoute,
        pendingRequests: pendingRequests,
        activeShipments: activeShipments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRoutePublishRequested(
    CourierDashboardRoutePublishRequested event,
    Emitter<CourierDashboardState> emit,
  ) async {
    try {
      final updated = await _routeRepo.updateRouteStatus(
          event.routeId, RouteStatus.published);
      final newRoutes = state.myRoutes
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
      final activeRoute = newRoutes.firstWhere(
        (r) => r.status == RouteStatus.published,
        orElse: () => updated,
      );
      emit(state.copyWith(myRoutes: newRoutes, activeRoute: activeRoute));
    } catch (e) {
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRouteArchiveRequested(
    CourierDashboardRouteArchiveRequested event,
    Emitter<CourierDashboardState> emit,
  ) async {
    try {
      final updated = await _routeRepo.updateRouteStatus(
          event.routeId, RouteStatus.removed);
      final newRoutes = state.myRoutes
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
      P2pRoute? newActiveRoute;
      for (final r in newRoutes) {
        if (r.status == RouteStatus.published) {
          newActiveRoute = r;
          break;
        }
      }
      // Build state directly so activeRoute can be cleared to null.
      emit(CourierDashboardState(
        status: state.status,
        profile: state.profile,
        activeRoute: newActiveRoute,
        myRoutes: newRoutes,
        pendingRequests: state.pendingRequests,
        activeShipments: state.activeShipments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAvailabilityToggled(
    CourierDashboardAvailabilityToggled event,
    Emitter<CourierDashboardState> emit,
  ) async {
    final previous = state.profile;
    if (previous == null) return;
    try {
      final updated =
          await _courierRepo.setAvailability(isActive: event.isActive);
      emit(state.copyWith(profile: updated));
    } catch (e) {
      // Surface the error to the UI so couriers can see why the toggle failed
      // (most commonly: courier is not yet APPROVED).
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
        profile: previous,
      ));
    }
  }

  Future<void> _onRequestAccepted(
    CourierDashboardRequestAccepted event,
    Emitter<CourierDashboardState> emit,
  ) async {
    try {
      final updated = await _courierRepo.acceptCourierRequest(
        event.requestId,
        offerAmountUsd: event.offerAmountUsd,
        message: event.message,
      );
      final newList = state.pendingRequests
          .where((r) => r.id != updated.id)
          .toList();
      emit(state.copyWith(pendingRequests: newList));
    } catch (e) {
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRequestDeclined(
    CourierDashboardRequestDeclined event,
    Emitter<CourierDashboardState> emit,
  ) async {
    try {
      final updated = await _courierRepo.declineCourierRequest(
        event.requestId,
        reason: event.reason,
      );
      final newList = state.pendingRequests
          .where((r) => r.id != updated.id)
          .toList();
      emit(state.copyWith(pendingRequests: newList));
    } catch (e) {
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLocationUpdated(
    CourierDashboardLocationUpdated event,
    Emitter<CourierDashboardState> emit,
  ) async {
    final previous = state.profile;
    if (previous == null) return;
    try {
      final updated = await _courierRepo.updateProfile({
        'homeLatitude': event.latitude,
        'homeLongitude': event.longitude,
      });
      emit(state.copyWith(profile: updated));
    } catch (e) {
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
        profile: previous,
      ));
    }
  }

  Future<void> _onSubmitForReviewRequested(
    CourierDashboardSubmitForReviewRequested event,
    Emitter<CourierDashboardState> emit,
  ) async {
    emit(state.copyWith(status: CourierDashboardStatus.loading));
    try {
      final updated = await _courierRepo.submitForReview();
      emit(state.copyWith(
        status: CourierDashboardStatus.success,
        profile: updated,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CourierDashboardStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
