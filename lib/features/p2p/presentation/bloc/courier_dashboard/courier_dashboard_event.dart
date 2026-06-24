part of 'courier_dashboard_bloc.dart';

abstract class CourierDashboardEvent {
  const CourierDashboardEvent();
}

class CourierDashboardLoadRequested extends CourierDashboardEvent {
  const CourierDashboardLoadRequested();
}

class CourierDashboardAvailabilityToggled extends CourierDashboardEvent {
  final bool isActive;
  const CourierDashboardAvailabilityToggled({required this.isActive});
}

class CourierDashboardRoutePublishRequested extends CourierDashboardEvent {
  final String routeId;
  const CourierDashboardRoutePublishRequested({required this.routeId});
}

class CourierDashboardRequestAccepted extends CourierDashboardEvent {
  final String requestId;
  final double? offerAmountUsd;
  final String? message;
  const CourierDashboardRequestAccepted({
    required this.requestId,
    this.offerAmountUsd,
    this.message,
  });
}

class CourierDashboardRequestDeclined extends CourierDashboardEvent {
  final String requestId;
  final String? reason;
  const CourierDashboardRequestDeclined({
    required this.requestId,
    this.reason,
  });
}

class CourierDashboardRouteArchiveRequested extends CourierDashboardEvent {
  final String routeId;
  const CourierDashboardRouteArchiveRequested({required this.routeId});
}

class CourierDashboardLocationUpdated extends CourierDashboardEvent {
  final double latitude;
  final double longitude;
  const CourierDashboardLocationUpdated({
    required this.latitude,
    required this.longitude,
  });
}

class CourierDashboardSubmitForReviewRequested extends CourierDashboardEvent {
  const CourierDashboardSubmitForReviewRequested();
}
