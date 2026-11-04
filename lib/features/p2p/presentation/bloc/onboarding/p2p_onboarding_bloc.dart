import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/domain/models/p2p_courier_profile.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';
import 'package:customer_nzubia_global/features/p2p/data/exceptions/p2p_exception.dart';

part 'p2p_onboarding_event.dart';
part 'p2p_onboarding_state.dart';


class P2pOnboardingBloc extends Bloc<P2pOnboardingEvent, P2pOnboardingState> {
  final P2pCourierRepository _courierRepo;

  P2pOnboardingBloc({
    required P2pCourierRepository courierRepository,
    P2pRouteRepository? routeRepository,
  })  : _courierRepo = courierRepository,
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
      stepIndex: 4,
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

      // 2. Prepare document URLs map for the background check endpoint
      final docUrlsMap = <String, String>{};
      for (final doc in docUrls) {
        final type = (doc['type'] as String?)?.toUpperCase() ?? '';
        final url = doc['url'] as String? ?? '';
        if (url.isEmpty) continue;
        if (type.contains('PASSPORT') ||
            type.contains('NATIONAL') ||
            type.contains('DRIVING') ||
            type.contains('RESIDENCE') ||
            type.contains('ID')) {
          docUrlsMap['idFront'] = url;
        } else if (type == 'SELFIE') {
          docUrlsMap['selfie'] = url;
        } else if (type == 'VISA') {
          docUrlsMap['visa'] = url;
        }
      }

      // 3. Format Date of Birth
      final rawDob = state.collectedData['dob'];
      String? dobFormatted;
      if (rawDob != null) {
        try {
          final dt =
              rawDob is DateTime ? rawDob : DateTime.parse(rawDob.toString());
          dobFormatted =
              '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } catch (_) {
          dobFormatted = rawDob.toString();
        }
      }

      // 4. Run automated real-time background check with documents
      final bgResult = await _courierRepo.verifyBackgroundCheck(
        firstName: state.collectedData['first_name'] as String?,
        lastName: state.collectedData['last_name'] as String?,
        dob: dobFormatted,
        state: state.collectedData['state'] as String?,
        documentUrls: docUrlsMap,
      );

      final isCleared =
          bgResult['status'] == 'CLEARED' || bgResult['success'] == true;
      if (!isCleared) {
        final reason = bgResult['message'] as String? ??
            'Verification failed. Background check flagged records. Application rejected. Please contact support.';
        throw P2pException.forbidden(reason);
      }

      // 5. Fetch the activated courier profile
      P2pCourierProfile? profile;
      try {
        profile = await _courierRepo.getMyProfile();
      } catch (_) {}

      emit(state.copyWith(
        status: OnboardingStatus.success,
        profile: profile,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: e.toString(),
        stepIndex: 4,
      ));
    }
  }

  /// Uploads passport, visa, and itinerary images to GCS and returns the
  /// list of `{type, url, uploaded_at}` maps ready for the KYC endpoint.
  Future<List<Map<String, dynamic>>> _uploadDocuments(
      Map<String, dynamic> data) async {
    final results = <Map<String, dynamic>>[];
    final idDocPath = data['id_document_path'] as String? ??
        data['passport_image_path'] as String? ??
        '';
    final selfiePath = data['selfie_image_path'] as String? ?? '';
    final visaPath = data['visa_image_path'] as String? ?? '';
    final itineraryPath = data['itinerary_image_path'] as String? ?? '';

    final rawIdType = (data['id_type'] as String?)?.trim() ?? 'PASSPORT';
    String docType = 'PASSPORT';
    if (rawIdType.toLowerCase().contains('national')) {
      docType = 'NATIONAL_ID';
    } else if (rawIdType.toLowerCase().contains('driver')) {
      docType = 'DRIVING_LICENSE';
    } else if (rawIdType.toLowerCase().contains('residence')) {
      docType = 'RESIDENCE_PERMIT';
    }

    final uploads = <String, String>{
      docType: idDocPath,
      'SELFIE': selfiePath,
      'VISA': visaPath,
      'ITINERARY': itineraryPath,
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

  void _onReset(P2pOnboardingReset event, Emitter<P2pOnboardingState> emit) {
    emit(const P2pOnboardingState());
  }
}
