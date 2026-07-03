import 'package:get_it/get_it.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/network/socket_client.dart';
import 'package:customer_nzubia_global/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_nzubia_global/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/shipment_repository.dart';
import 'package:customer_nzubia_global/features/shipment/data/repositories/shipment_repository_impl.dart';
import 'package:customer_nzubia_global/features/shipment/domain/repositories/quote_repository.dart';
import 'package:customer_nzubia_global/features/shipment/data/repositories/quote_repository_impl.dart';
import 'package:customer_nzubia_global/core/services/payment_service.dart';
import 'package:customer_nzubia_global/core/services/stripe_payment_service.dart';
import 'package:customer_nzubia_global/core/services/deep_link_service.dart';
import 'package:customer_nzubia_global/core/services/firebase_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:customer_nzubia_global/features/tracking/domain/repositories/tracking_repository.dart' as legacy_tracking_repo;
import 'package:customer_nzubia_global/features/tracking/data/repositories/tracking_repository_impl.dart' as legacy_tracking_impl;
import 'package:customer_nzubia_global/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:customer_nzubia_global/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:customer_nzubia_global/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:customer_nzubia_global/features/messaging/data/datasources/messaging_remote_datasource_impl.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/bloc/chat/chat_bloc.dart';
import 'package:customer_nzubia_global/features/profile/domain/repositories/profile_repository.dart';
import 'package:customer_nzubia_global/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/shipment_list/shipment_list_bloc.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/bloc/quote_list/quote_list_bloc.dart';
import 'package:customer_nzubia_global/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:customer_nzubia_global/features/payment/data/datasources/payment_remote_datasource_impl.dart';
import 'package:customer_nzubia_global/features/payment/domain/repositories/payment_repository.dart';
import 'package:customer_nzubia_global/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:customer_nzubia_global/features/payout/data/repositories/payout_repository.dart';
import 'package:customer_nzubia_global/core/services/biometric_service.dart';
import 'package:customer_nzubia_global/features/profile/data/repositories/legal_repository.dart';

// ── P2P – domain interfaces ───────────────────────────────────────────────────
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_courier_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_route_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_shipment_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_compliance_repository.dart';
import 'package:customer_nzubia_global/features/p2p/domain/repositories/p2p_review_repository.dart';

// ── P2P – data implementations ────────────────────────────────────────────────
import 'package:customer_nzubia_global/features/p2p/data/repositories/p2p_courier_repository_impl.dart';
import 'package:customer_nzubia_global/features/p2p/data/repositories/p2p_route_repository_impl.dart';
import 'package:customer_nzubia_global/features/p2p/data/repositories/p2p_shipment_repository_impl.dart';
import 'package:customer_nzubia_global/features/p2p/data/repositories/p2p_compliance_repository_impl.dart';
import 'package:customer_nzubia_global/features/p2p/data/repositories/p2p_review_repository_impl.dart';

// ── P2P – BLoCs ───────────────────────────────────────────────────────────────
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/courier/courier_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/marketplace/marketplace_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/shipment/p2p_shipment_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/onboarding/p2p_onboarding_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/courier_dashboard/courier_dashboard_bloc.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/bloc/compliance/p2p_compliance_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Network
  // Network
  // sl.registerLazySingleton<DioClient>(() => DioClient()); // Removed incorrect registration

  // Repositories
  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));

  sl.registerLazySingleton<ShipmentRepository>(() => ShipmentRepositoryImpl(sl()));

  sl.registerLazySingleton<QuoteRepository>(() => QuoteRepositoryImpl(sl()));

  // Network
  sl.registerLazySingleton(() => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  ));
  sl.registerLazySingleton(() => DioClient(sl()));
  sl.registerLazySingleton<SocketClient>(() => SocketClient(sl()));

  // Services
  sl.registerLazySingleton<DeepLinkService>(() => DeepLinkService());
  sl.registerLazySingleton<PaymentService>(() => StripePaymentService(sl()));
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService(sl()));
  sl.registerLazySingleton<BiometricService>(() => BiometricService());
  sl.registerLazySingleton<legacy_tracking_repo.TrackingRepository>(() => legacy_tracking_impl.TrackingRepositoryImpl(sl()));

  // Messaging
  sl.registerLazySingleton<MessagingRemoteDatasource>(() => MessagingRemoteDatasourceImpl(sl(), sl()));
  sl.registerLazySingleton<MessagingRepository>(() => MessagingRepositoryImpl(
    remoteDatasource: sl(),
    authRepository: sl(),
  ));

  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl()));

  // BLoCs
  sl.registerFactory<AuthBloc>(() => AuthBloc(authRepository: sl()));
  sl.registerFactory<ChatBloc>(() => ChatBloc(messagingRepository: sl()));
  sl.registerFactory<ShipmentListBloc>(() => ShipmentListBloc(
    shipmentRepository: sl(),
    socketClient: sl(),
  ));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(
    shipmentRepository: sl(),
    paymentRepository: sl(),
  ));
  sl.registerFactory<QuoteListBloc>(() => QuoteListBloc(quoteRepository: sl()));

  // Payment
  sl.registerLazySingleton<PaymentRemoteDatasource>(() => PaymentRemoteDatasourceImpl(sl()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(sl()));

  // Payout
  sl.registerLazySingleton<PayoutRepository>(() => PayoutRepositoryImpl(sl()));

  // Legal
  sl.registerLazySingleton<LegalRepository>(() => LegalRepository(sl()));

  // ── P2P repositories ────────────────────────────────────────────────────────
  sl.registerLazySingleton<P2pCourierRepository>(
    () => P2pCourierRepositoryImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<P2pRouteRepository>(
    () => P2pRouteRepositoryImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<P2pShipmentRepository>(
    () => P2pShipmentRepositoryImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<P2pComplianceRepository>(
    () => P2pComplianceRepositoryImpl(client: sl<DioClient>()),
  );
  sl.registerLazySingleton<P2pReviewRepository>(
    () => P2pReviewRepositoryImpl(client: sl<DioClient>()),
  );

  // ── P2P BLoCs (factories so each screen gets a fresh instance) ──────────────
  sl.registerFactory<CourierBloc>(
    () => CourierBloc(repository: sl<P2pCourierRepository>()),
  );
  sl.registerFactory<MarketplaceBloc>(
    () => MarketplaceBloc(
      repository: sl<P2pRouteRepository>(),
      courierRepository: sl<P2pCourierRepository>(),
    ),
  );
  sl.registerFactory<P2pShipmentBloc>(
    () => P2pShipmentBloc(repository: sl<P2pShipmentRepository>()),
  );

  // P2pOnboardingBloc is a factory so each wizard flow gets a fresh instance
  sl.registerFactory<P2pOnboardingBloc>(
    () => P2pOnboardingBloc(
      courierRepository: sl<P2pCourierRepository>(),
      routeRepository: sl<P2pRouteRepository>(),
    ),
  );

  // ── P2P – Courier Dashboard (factory – fresh per visit) ─────────────────────
  sl.registerFactory<CourierDashboardBloc>(
    () => CourierDashboardBloc(
      courierRepository: sl<P2pCourierRepository>(),
      routeRepository: sl<P2pRouteRepository>(),
      shipmentRepository: sl<P2pShipmentRepository>(),
    ),
  );

  // ── P2P – Compliance (factory) ───────────────────────────────────────────────
  sl.registerFactory<P2pComplianceBloc>(
    () => P2pComplianceBloc(repository: sl<P2pComplianceRepository>()),
  );
}
