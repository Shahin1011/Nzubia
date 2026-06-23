import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';

part 'p2p_onboarding_event.dart';
part 'p2p_onboarding_state.dart';

/// Keys carried inside `collectedData` that the bloc maps onto courier-apply
/// and route-create payloads at submit time.
class _OnboardingKeys {
  // Courier profile (matches CreateCourierProfileDto on the backend)
  static const homeLatitude = 'homeLatitude';
  static const homeLongitude = 'homeLongitude';
  static const serviceRadiusKm = 'serviceRadiusKm';
  static const acceptedCategories = 'acceptedCategories';

  // Optional initial route (matches CreateRouteDto)
  static const destinationCountry = 'destinationCountry';
  static const destinationCity = 'destinationCity';
  static const departureDate = 'departureDate';
  static const returnDate = 'returnDate';
  static const pickupOrigin = 'pickupOrigin';
  static const pickupLatitude = 'pickupLatitude';
  static const pickupLongitude = 'pickupLongitude';
  static const capacityKg = 'capacityKg';
  static const acceptedItemCategories = 'acceptedItemCategories';
  static const routeNotes = 'routeNotes';
}

class P2pOnboardingBloc extends Bloc<P2pOnboardingEvent, P2pOnboardingState> {
  final P2pCourierRepository _courierRepo;
  final P2pRouteRepository _routeRepo;

  P2pOnboardingBloc({
    required P2pCourierRepository courierRepository,
    required P2pRouteRepository routeRepository,
  })  : _courierRepo = courierRepository,
        _routeRepo = routeRepository,
        super(const P2pOnboardingState()) {
    on<P2pOnboardingStarted>(_onStarted);
    on<P2pOnboardingProfileSubmitted>(_onProfileSubmitted);
    on<P2pOnboardingIdentitySubmitted>(_onIdentitySubmitted);
    on<P2pOnboardingDocumentsSubmitted>(_onDocumentsSubmitted);
    on<P2pOnboardingRouteSubmitted>(_onRouteSubmitted);
    on<P2pOnboardingComplianceSubmitted>(_onComplianceSubmitted);
    on<P2pOnboardingConfirmSubmit>(_onConfirmSubmit);
    on<P2pOnboardingReset>(_onReset);
  }

  void _onStarted(P2pOnboardingStarted event, Emitter<P2pOnboardingState> emit) {
    emit(const P2pOnboardingState(
      status: OnboardingStatus.step,
      stepIndex: 0,
      collectedData: {},
    ));
  }

  void _onProfileSubmitted(
    P2pOnboardingProfileSubmitted event,
    Emitter<P2pOnboardingState> emit,
  ) {
    final merged = Map<String, dynamic>.from(state.collectedData)
      ..addAll(event.data);
    emit(state.copyWith(
      status: OnboardingStatus.step,
      stepIndex: 1,
      collectedData: merged,
    ));
  }

  void _onIdentitySubmitted(
    P2pOnboardingIdentitySubmitted event,
    Emitter<P2pOnboardingState> emit,
  ) {
    final merged = Map<String, dynamic>.from(state.collectedData)
      ..addAll(event.data);
    emit(state.copyWith(
      status: OnboardingStatus.step,
      stepIndex: 2,
      collectedData: merged,
    ));
  }

  void _onDocumentsSubmitted(
    P2pOnboardingDocumentsSubmitted event,
    Emitter<P2pOnboardingState> emit,
  ) {
    final merged = Map<String, dynamic>.from(state.collectedData)
      ..addAll(event.data);
    emit(state.copyWith(
      status: OnboardingStatus.step,
      stepIndex: 3,
      collectedData: merged,
    ));
  }

  void _onRouteSubmitted(
    P2pOnboardingRouteSubmitted event,
    Emitter<P2pOnboardingState> emit,
  ) {
    final merged = Map<String, dynamic>.from(state.collectedData)
      ..addAll(event.data);
    emit(state.copyWith(
      status: OnboardingStatus.step,
      stepIndex: 4,
      collectedData: merged,
    ));
  }

  void _onComplianceSubmitted(
    P2pOnboardingComplianceSubmitted event,
    Emitter<P2pOnboardingState> emit,
  ) {
    final merged = Map<String, dynamic>.from(state.collectedData)
      ..addAll(event.data);
    emit(state.copyWith(
      status: OnboardingStatus.step,
      stepIndex: 5,
      collectedData: merged,
    ));
  }

  Future<void> _onConfirmSubmit(
    P2pOnboardingConfirmSubmit event,
    Emitter<P2pOnboardingState> emit,
  ) async {
    emit(state.copyWith(status: OnboardingStatus.submitting));
    try {
      // 1. Upload document images to GCS and collect their URLs.
      final docUrls = await _uploadDocuments(state.collectedData);

      // 2. Create the courier profile with service preferences.
      final profilePayload = _extractCourierData(state.collectedData);
      final profile = await _courierRepo.applyAsCourier(profilePayload);

      // 3. Save KYC identity data and the uploaded document URLs.
      final identity = _extractIdentityData(state.collectedData);
      if (identity.isNotEmpty || docUrls.isNotEmpty) {
        try {
          await _courierRepo.submitKyc(
            identity: identity,
            documentUrls: docUrls,
          );
        } catch (_) {
          // KYC save failure is non-fatal — the courier can re-upload later.
        }
      }

      // 4. Optionally create the initial route in DRAFT.
      final routeData = _extractRouteData(state.collectedData);
      if (routeData.isNotEmpty) {
        try {
          await _routeRepo.createRoute(routeData);
        } catch (_) {
          // intentionally swallowed
        }
      }

      // 5. Transition the profile to PENDING_REVIEW so it appears in the
      //    admin verification queue.
      await _courierRepo.submitForReview();

      emit(state.copyWith(
        status: OnboardingStatus.success,
        profile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: e.toString(),
        stepIndex: 5,
      ));
    }
  }

  /// Uploads passport, visa, and itinerary images to GCS and returns the
  /// list of `{type, url, uploaded_at}` maps ready for the KYC endpoint.
  Future<List<Map<String, dynamic>>> _uploadDocuments(
      Map<String, dynamic> data) async {
    final results = <Map<String, dynamic>>[];
    final uploads = <String, String>{
      'PASSPORT': data['passport_image_path'] as String? ?? '',
      'VISA': data['visa_image_path'] as String? ?? '',
      'ITINERARY': data['itinerary_image_path'] as String? ?? '',
    };

    for (final entry in uploads.entries) {
      if (entry.value.isEmpty) continue;
      try {
        final url = await _courierRepo.uploadDocument(
            entry.value, 'p2p-courier-kyc');
        results.add({
          'type': entry.key,
          'url': url,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Skip failed uploads — admin will see which docs are missing.
      }
    }
    return results;
  }

  Map<String, dynamic> _extractIdentityData(Map<String, dynamic> data) {
    const keys = [
      'full_name', 'first_name', 'last_name', 'dob',
      'nationality', 'address_line1', 'id_type', 'id_number',
    ];
    return {
      for (final k in keys)
        if (data[k] != null) k: data[k],
    };
  }

  void _onReset(P2pOnboardingReset event, Emitter<P2pOnboardingState> emit) {
    emit(const P2pOnboardingState());
  }

  Map<String, dynamic> _extractCourierData(Map<String, dynamic> data) {
    const keys = [
      _OnboardingKeys.homeLatitude,
      _OnboardingKeys.homeLongitude,
      _OnboardingKeys.serviceRadiusKm,
      _OnboardingKeys.acceptedCategories,
    ];
    return {
      for (final k in keys)
        if (data[k] != null) k: data[k],
    };
  }

  Map<String, dynamic> _extractRouteData(Map<String, dynamic> data) {
    const required = [
      _OnboardingKeys.destinationCountry,
      _OnboardingKeys.destinationCity,
      _OnboardingKeys.departureDate,
      _OnboardingKeys.pickupOrigin,
      _OnboardingKeys.capacityKg,
    ];
    final hasRequired = required.every((k) => data[k] != null);
    if (!hasRequired) return const {};

    const optional = [
      _OnboardingKeys.returnDate,
      _OnboardingKeys.pickupLatitude,
      _OnboardingKeys.pickupLongitude,
      _OnboardingKeys.acceptedItemCategories,
      _OnboardingKeys.routeNotes,
    ];

    return {
      for (final k in [...required, ...optional])
        if (data[k] != null) k: data[k],
    };
  }
}
