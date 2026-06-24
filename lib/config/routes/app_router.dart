import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ── P2P ───────────────────────────────────────────────────────────────────────
import 'package:customer_nzubia_global/features/p2p/presentation/pages/p2p_marketplace_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_apply_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_onboarding_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_identity_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_documents_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_route_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/post_route_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_compliance_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_review_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_dashboard_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_matched_shipments_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_requests_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_pickup_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_in_transit_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/couriers_list_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_profile_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/courier/courier_payout_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_create_shipment_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_shipment_detail_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_my_shipments_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_awaiting_offers_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_waiver_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_handoff_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_tracking_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_review_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/shipment/p2p_payment_screen.dart';
import 'package:customer_nzubia_global/features/p2p/presentation/pages/compliance_screen.dart';

import 'package:customer_nzubia_global/features/auth/presentation/pages/splash_screen.dart';
import 'package:customer_nzubia_global/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:customer_nzubia_global/features/auth/presentation/pages/login_screen.dart';
import 'package:customer_nzubia_global/features/auth/presentation/pages/register_screen.dart';
import 'package:customer_nzubia_global/features/auth/presentation/pages/otp_verification_screen.dart';
import 'package:customer_nzubia_global/features/auth/presentation/pages/profile_setup_screen.dart';
import 'package:customer_nzubia_global/features/auth/presentation/pages/agent_onboarding_screen.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/pages/agent_dashboard_screen.dart';
import 'package:customer_nzubia_global/features/home/presentation/pages/scaffold_with_navbar.dart';
import 'package:customer_nzubia_global/features/home/presentation/pages/home_screen.dart';
import 'package:customer_nzubia_global/features/tracking/presentation/pages/tracking_detail_screen.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/pages/chat_list_screen.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/pages/chat_room_screen.dart';
import 'package:customer_nzubia_global/features/profile/presentation/pages/profile_screen.dart';
import 'package:customer_nzubia_global/features/profile/presentation/pages/agent_payout_settings_screen.dart';
import 'package:customer_nzubia_global/features/profile/presentation/pages/edit_profile_screen.dart';
import 'package:customer_nzubia_global/features/profile/domain/entities/user_profile_entity.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/shipment_wizard_screen.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/quote_list_screen.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/checkout_screen.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/shipment_detail/shipment_detail_screen.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/shipment_entity.dart';
import 'package:customer_nzubia_global/features/shipment/domain/entities/quote_entity.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/agent_shipment_list_screen.dart';
import 'package:customer_nzubia_global/features/quotes/presentation/pages/create_quote_screen.dart';
import 'package:customer_nzubia_global/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:customer_nzubia_global/features/profile/presentation/pages/legal_doc_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/features/messaging/presentation/bloc/chat/chat_bloc.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/payment_success_screen.dart';
import 'package:customer_nzubia_global/features/payment/presentation/pages/payment_history_screen.dart';
import 'package:customer_nzubia_global/features/payment/presentation/pages/payment_cancel_screen.dart';
import 'package:customer_nzubia_global/features/shipment/presentation/pages/tracking_screen.dart';
import 'package:customer_nzubia_global/features/payout/presentation/pages/bank_account_setup_screen.dart';
import 'package:customer_nzubia_global/features/dashboard/presentation/pages/transaction_detail_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _chatsNavKey = GlobalKey<NavigatorState>(debugLabel: 'chats');
final GlobalKey<NavigatorState> _p2pNavKey = GlobalKey<NavigatorState>(debugLabel: 'p2p');
final GlobalKey<NavigatorState> _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Auth Routes (Outside Shell)
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/otp', builder: (context, state) => const OtpVerificationScreen()),
      GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(path: '/agent-onboarding', builder: (context, state) => const AgentOnboardingScreen()),
      GoRoute(path: '/agent-dashboard', builder: (context, state) => const AgentDashboardScreen()),

      // Main App Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavbar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home / Dashboard
          StatefulShellBranch(
            navigatorKey: _homeNavKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 2: Messages
          StatefulShellBranch(
            navigatorKey: _chatsNavKey,
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          // Branch 3 – P2P marketplace
          StatefulShellBranch(
            navigatorKey: _p2pNavKey,
            routes: [
              GoRoute(
                path: '/p2p',
                builder: (context, state) => const P2pMarketplaceScreen(),
                routes: [
                  GoRoute(
                    path: 'courier/dashboard',
                    builder: (context, state) =>
                        const CourierDashboardScreen(),
                  ),
                  GoRoute(
                    path: 'compliance',
                    builder: (context, state) => const P2pComplianceScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Courier onboarding (full-screen wizard) ──────────────────────────
      GoRoute(
        path: '/p2p/courier/apply',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierApplyScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierOnboardingScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/identity',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierIdentityScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/documents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierDocumentsScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/route',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierRouteScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/compliance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierComplianceScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierReviewScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/post-route',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PostRouteScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/matched-shipments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierMatchedShipmentsScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/requests',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierRequestsScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/payout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierPayoutScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/shipment/:id/pickup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CourierPickupScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/p2p/courier/shipment/:id/in-transit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CourierInTransitScreen(shipmentId: id);
        },
      ),
      // ── P2P shipment (full-screen) ────────────────────────────────────────
      GoRoute(
        path: '/p2p/my-shipments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const P2pMyShipmentsScreen(),
      ),
      GoRoute(
        path: '/p2p/shipment/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const P2pCreateShipmentScreen(),
      ),
      GoRoute(
        path: '/p2p/shipment/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return P2pShipmentDetailScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/p2p/shipment/:id/offers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return P2pAwaitingOffersScreen(
            shipmentId: id,
            destinationCity: extra?['destinationCity'] as String?,
            destinationCountry: extra?['destinationCountry'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/p2p/shipment/:id/payment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return P2pPaymentScreen(
            shipmentId: id,
            offerId: extra['offerId'] as String? ?? '',
            clientSecret: extra['clientSecret'] as String? ?? '',
            amountUsd: (extra['amountUsd'] as num?)?.toDouble() ?? 0,
            courierName: extra['courierName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/p2p/shipment/:id/waiver',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return P2pWaiverScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/p2p/shipment/:id/handoff',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return P2pHandoffScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/p2p/shipment/:id/tracking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return P2pTrackingScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/p2p/shipment/:id/review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return P2pReviewScreen(shipmentId: id);
        },
      ),
      // ── Couriers list (full-screen) ──────────────────────────────────────
      GoRoute(
        path: '/p2p/couriers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CouriersListScreen(),
      ),
      // ── Courier public profile (full-screen) ─────────────────────────────
      GoRoute(
        path: '/p2p/couriers/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CourierProfileScreen(courierId: id);
        },
      ),

      // ── Alias routes (spec-friendly /p2p/seeker/* and short /p2p/courier/*) ─
      GoRoute(
        path: '/p2p/seeker/awaiting-offers/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, state) =>
            '/p2p/shipment/${state.pathParameters['id']}/offers',
      ),
      GoRoute(
        path: '/p2p/seeker/waiver/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, state) =>
            '/p2p/shipment/${state.pathParameters['id']}/waiver',
      ),
      GoRoute(
        path: '/p2p/seeker/handoff/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, state) =>
            '/p2p/shipment/${state.pathParameters['id']}/handoff',
      ),
      GoRoute(
        path: '/p2p/seeker/tracking/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, state) =>
            '/p2p/shipment/${state.pathParameters['id']}/tracking',
      ),
      GoRoute(
        path: '/p2p/seeker/review/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, state) =>
            '/p2p/shipment/${state.pathParameters['id']}/review',
      ),
      GoRoute(
        path: '/p2p/seeker/courier-profile/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (_, state) =>
            '/p2p/couriers/${state.pathParameters['id']}',
      ),
      // Short courier aliases
      GoRoute(
        path: '/p2p/courier/route/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PostRouteScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/shipments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CourierMatchedShipmentsScreen(),
      ),
      GoRoute(
        path: '/p2p/courier/pickup/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CourierPickupScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/p2p/courier/in-transit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CourierInTransitScreen(shipmentId: id);
        },
      ),

      // Standalone Routes (Pushed on top)
      GoRoute(
        path: '/create-shipment',
        builder: (context, state) => const ShipmentWizardScreen(),
      ),
      GoRoute(
        path: '/shipment-details',
        builder: (context, state) {
          final shipment = state.extra as ShipmentEntity;
          return ShipmentDetailScreen(shipment: shipment);
        },
      ),
      GoRoute(
        path: '/shipment/:id/quotes',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final shipment = state.extra as ShipmentEntity?;
          return QuoteListScreen(shipmentId: id, shipment: shipment);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CheckoutScreen(
            quoteId: extra['quoteId'],
            amount: extra['amount'],
            currency: extra['currency'],
          );
        },
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (context, state) {
           final id = state.pathParameters['id']!;
           return TrackingDetailScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final agentName = state.extra as String? ?? 'Agent';
          return BlocProvider(
            create: (context) => ChatBloc(messagingRepository: sl()),
            child: ChatRoomScreen(chatId: id, agentName: agentName),
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          final profile = state.extra as UserProfileEntity;
          return EditProfileScreen(profile: profile);
        },
      ),
      GoRoute(
        path: '/profile/payout-settings',
        builder: (context, state) {
          final profile = state.extra as UserProfileEntity;
          return AgentPayoutSettingsScreen(profile: profile);
        },
      ),
      GoRoute(
        path: '/agent/shipments/:status',
        builder: (context, state) {
           final status = state.pathParameters['status']!;
           final title = state.extra as String? ?? 'Shipments';
           return AgentShipmentListScreen(filterStatus: status, title: title);
        },
      ),
      GoRoute(
        path: '/agent/quote/create',
        builder: (context, state) {
           final extra = state.extra;
           ShipmentEntity shipment;
           QuoteEntity? quote;

           if (extra is ShipmentEntity) {
             shipment = extra;
           } else if (extra is Map) {
             shipment = extra['shipment'] as ShipmentEntity;
             quote = extra['quote'] as QuoteEntity?;
           } else {
             throw Exception('Invalid extra params for create/edit quote');
           }

           return CreateQuoteScreen(shipment: shipment, quote: quote);
        },
      ),
      GoRoute(
        path: '/payment/success',
        builder: (context, state) => const PaymentSuccessScreen(),
      ),
      // Handling deep link variation (nzubia://payment/success -> /success)
      GoRoute(
        path: '/success',
        redirect: (context, state) => '/payment/success',
      ),
      GoRoute(
        path: '/payment-success',
        redirect: (context, state) => '/payment/success',
      ),
      GoRoute(
        path: '/payment/cancel',
        builder: (context, state) => const PaymentCancelScreen(),
      ),

      // Guest tracking by tracking number (distinct path from /tracking/:id)
      GoRoute(
        path: '/track/:trackingNumber',
        builder: (context, state) {
          final trackingNumber = state.pathParameters['trackingNumber']!;
          return TrackingScreen(trackingNumber: trackingNumber);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/payment-history',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/bank-setup',
        builder: (context, state) => const BankAccountSetupScreen(),
      ),
      GoRoute(
        path: '/legal/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final title = state.extra as String? ?? 'Legal';
          return LegalDocScreen(slug: slug, title: title);
        },
      ),
      GoRoute(
        path: '/agent/transaction-detail',
        builder: (context, state) {
          final transaction = state.extra as Map<String, dynamic>;
          return TransactionDetailScreen(transaction: transaction);
        },
      ),
    ],
  );
}

