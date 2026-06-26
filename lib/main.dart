import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:customer_nzubia_global/config/routes/app_router.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/core/theme/app_theme.dart';
import 'package:customer_nzubia_global/core/utils/service_locator.dart';
import 'package:customer_nzubia_global/core/services/deep_link_service.dart';
import 'package:customer_nzubia_global/core/services/firebase_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:customer_nzubia_global/features/auth/presentation/bloc/auth/auth_event.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:customer_nzubia_global/core/theme/theme_cubit.dart';
import 'package:customer_nzubia_global/core/localization/language_cubit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:customer_nzubia_global/l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  Stripe.publishableKey = ApiConstants.stripePublishableKey;
  await Stripe.instance.applySettings();
  await setupServiceLocator();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Run App immediately to prevent iOS Watchdog termination on slow networks
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://1b0ad525c6a07c42a0313623d7143bee@o4510935086596096.ingest.us.sentry.io/4510935088168960';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = false; // Do not send IP addresses or auth headers to Sentry
      options.enableLogs = true;
      options.tracesSampleRate = 0.1; // 10% of transactions — sufficient for performance insights
      options.profilesSampleRate = 0.1; // Relative to tracesSampleRate
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () {
      runApp(SentryWidget(child: const MyApp()));
      FlutterNativeSplash.remove();
    },
  );
  
  // Initialize services in background
  unawaited(_initBackgroundServices());
}

Future<void> _initBackgroundServices() async {
  try {
    // Initialize Deep Links
    try {
      sl<DeepLinkService>().initialize();
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize DeepLinkService: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
    }

    // Initialize Firebase (Dynamic)
    try {
      await sl<FirebaseService>().initialize();
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize FirebaseService: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
    }

    // Initialize OneSignal
    if (!kIsWeb) {
      try {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize("78cbef11-09fe-4ae7-b4d4-fd0ecea2dc85");
        
        // Delay prompt slightly to ensure UI is ready on iOS
        Future.delayed(const Duration(seconds: 2), () {
          OneSignal.Notifications.requestPermission(true);
        });

        // Notification Handler
        OneSignal.Notifications.addClickListener((event) {
          final data = event.notification.additionalData;
          debugPrint('OneSignal Notification Clicked: $data');
          if (data != null) {
             final shipmentId = data['shipment_id'] ?? data['id'];
             final type = data['type'];
             final chatId = data['chat_id'] ?? data['room_id'] ?? data['userId'];

             if ((type == 'QUOTE_RECEIVED' || type == 'NEW_QUOTE') && shipmentId != null) {
                AppRouter.router.push('/shipment/$shipmentId/quotes');
             } else if ((type == 'SHIPMENT_UPDATE' || type == 'STATUS_CHANGED' || type == 'SHIPMENT_BOOKED') && shipmentId != null) {
                AppRouter.router.push('/shipment/$shipmentId');
             } else if (type == 'MESSAGE_RECEIVED' || type == 'NEW_MESSAGE') {
                 if (chatId != null) {
                    AppRouter.router.push('/chat/$chatId');
                 } else {
                    AppRouter.router.push('/chats');
                 }
             } else if (type == 'PAYMENT_SUCCESS') {
                AppRouter.router.push('/payment/success');
             }
             // ── P2P notification deep-links ─────────────────────────────────
             else if ((type == 'P2P_OFFER_RECEIVED' || type == 'P2P_NEW_OFFER') && shipmentId != null) {
                AppRouter.router.push('/p2p/shipment/$shipmentId/offers');
             } else if (type == 'P2P_PICKUP_CONFIRMED' && shipmentId != null) {
                AppRouter.router.push('/p2p/shipment/$shipmentId/tracking');
             } else if (type == 'P2P_STATUS_UPDATE' && shipmentId != null) {
                AppRouter.router.push('/p2p/shipment/$shipmentId/tracking');
             } else if ((type == 'P2P_OFFER_ACCEPTED' || type == 'P2P_REQUEST_ACCEPTED') && shipmentId != null) {
                // Courier: offer accepted → go straight to pickup screen
                AppRouter.router.push('/p2p/courier/shipment/$shipmentId/pickup');
             } else if (type == 'P2P_MATCHED_SHIPMENT') {
                // Courier: new shipment matching their route
                AppRouter.router.push('/p2p/courier/matched-shipments');
             } else if (type == 'P2P_DIRECT_REQUEST') {
                // Courier: seeker sent a direct booking request
                AppRouter.router.push('/p2p/courier/requests');
             }
          }
        });
      } catch (e, stackTrace) {
        debugPrint('Failed to initialize OneSignal: $e');
        Sentry.captureException(e, stackTrace: stackTrace);
      }
    }
  } catch (e, stackTrace) {
    debugPrint('Global background services error: $e');
    Sentry.captureException(e, stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthBloc>()..add(AppStarted())),
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(create: (context) => LanguageCubit()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return MaterialApp.router(
                title: 'Nzubia',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                routerConfig: AppRouter.router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  HaitianCreoleMaterialLocalizations.delegate,
                  HaitianCreoleCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'),
                  Locale('es'),
                  Locale('pt'),
                  Locale('ht'),
                  Locale('fr'),
                ],
                locale: locale,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}


class HaitianCreoleMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const HaitianCreoleMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return SynchronousFuture<MaterialLocalizations>(const HaitianCreoleMaterialLocalizations());
  }

  @override
  bool shouldReload(HaitianCreoleMaterialLocalizationsDelegate old) => false;
}

class HaitianCreoleMaterialLocalizations extends DefaultMaterialLocalizations {
  const HaitianCreoleMaterialLocalizations();

  static const LocalizationsDelegate<MaterialLocalizations> delegate = HaitianCreoleMaterialLocalizationsDelegate();
}

class HaitianCreoleCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const HaitianCreoleCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return SynchronousFuture<CupertinoLocalizations>(const HaitianCreoleCupertinoLocalizations());
  }

  @override
  bool shouldReload(HaitianCreoleCupertinoLocalizationsDelegate old) => false;
}

class HaitianCreoleCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const HaitianCreoleCupertinoLocalizations();

  static const LocalizationsDelegate<CupertinoLocalizations> delegate = HaitianCreoleCupertinoLocalizationsDelegate();
}
