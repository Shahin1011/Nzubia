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
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';

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
      final initialProfile = await _courierRepo.getMyProfile();
      if (initialProfile == null) {
        emit(state.copyWith(
          status: CourierDashboardStatus.failure,
          errorMessage: 'No courier profile found. Please apply first.',
        ));
        return;
      }

      var profile = initialProfile;
      // Sync real-time Stripe Connect payout readiness
      try {
        final stripeStatus = await _courierRepo.getStripeConnectStatus();
        profile = initialProfile.copyWith(payoutReady: stripeStatus.payoutReady);
      } catch (_) {}

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
        if (r.hasValidRouteData && r.status == RouteStatus.published) {
          activeRoute = r;
          break;
        }
      }
      if (activeRoute == null && myRoutes.isNotEmpty) {
        final valid = myRoutes.where((r) => r.hasValidRouteData).toList();
        if (valid.isNotEmpty) {
          activeRoute = valid.first;
        }
      }
      // If routes list is empty or doesn't have an active route, but courier profile has an active destination_route:
      final rawDest = profile.destinationRoute?.trim();
      final hasRealDest = rawDest != null &&
          rawDest.isNotEmpty &&
          rawDest.toLowerCase() != 'global';
      if (activeRoute == null && hasRealDest) {
        String destCity = '';
        String destCountry = rawDest;
        if (destCountry.contains(',')) {
          final parts = destCountry.split(',');
          destCity = parts.first.trim();
          destCountry = parts.sublist(1).join(',').trim();
        }
        activeRoute = P2pRoute(
          id: profile.id,
          courierProfileId: profile.id,
          destinationCity: destCity,
          destinationCountry: destCountry,
          departureDate: profile.departureDate ?? DateTime.now(),
          returnDate: profile.returnDate,
          pickupOrigin: (profile.pickupOrigin != null && profile.pickupOrigin!.isNotEmpty)
              ? profile.pickupOrigin!
              : 'Current Location',
          capacityKg: profile.capacityKg ?? 0.0,
          status: RouteStatus.published,
        );
        if (myRoutes.isEmpty) {
          myRoutes = [activeRoute];
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

      List<P2pShipmentRequest> disputedShipments = const [];
      try {
        disputedShipments = await _shipmentRepo.listMyDisputedShipments();
      } catch (_) {
        // Non-fatal — dashboard still works without dispute data.
      }

      emit(state.copyWith(
        status: CourierDashboardStatus.success,
        profile: profile,
        myRoutes: myRoutes,
        activeRoute: activeRoute,
        pendingRequests: pendingRequests,
        activeShipments: activeShipments,
        disputedShipments: disputedShipments,
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
      try {
        final dest = [updated.destinationCity, updated.destinationCountry]
            .where((s) => s.trim().isNotEmpty)
            .join(', ');
        await sl<DioClient>().dio.patch(
          ApiConstants.courierLocation,
          data: {
            'is_available': true,
            'location': {
              'destination_route': dest,
            },
          },
        );
      } catch (_) {}
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
        disputedShipments: state.disputedShipments,
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

    // Optimistically update the UI so toggle switch responds immediately
    final optimistic = previous.copyWith(isActive: event.isActive);
    emit(state.copyWith(
      status: CourierDashboardStatus.success,
      profile: optimistic,
      errorMessage: null,
    ));

    try {
      final updated =
          await _courierRepo.setAvailability(isActive: event.isActive);
      emit(state.copyWith(
        status: CourierDashboardStatus.success,
        profile: updated,
      ));
    } catch (e) {
      // Revert the switch back to previous without breaking dashboard view!
      final cleanMsg = e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('P2pException: ', '')
          .replaceAll('Courier not found.', 'Could not update status on server.');
      emit(state.copyWith(
        status: CourierDashboardStatus.success,
        profile: previous,
        errorMessage: cleanMsg,
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
      try {
        final dest = state.activeRoute != null
            ? [state.activeRoute!.destinationCity, state.activeRoute!.destinationCountry]
                .where((s) => s.trim().isNotEmpty)
                .join(', ')
            : null;
        await sl<DioClient>().dio.patch(
          ApiConstants.courierLocation,
          data: {
            'is_available': updated.isActive,
            'location': {
              'lat': event.latitude,
              'lng': event.longitude,
              if (dest != null && dest.isNotEmpty) 'destination_route': dest,
            },
          },
        );
      } catch (_) {}
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
