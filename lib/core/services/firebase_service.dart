import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';
import 'package:customer_nzubia_global/config/routes/app_router.dart';
import 'package:customer_nzubia_global/features/notifications/presentation/bloc/notifications_bloc.dart';

class FirebaseService {
  final DioClient _dioClient;
  static Future<void>? _initializationFuture;
  String? _fcmToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FirebaseService(this._dioClient);

  String? get fcmToken => _fcmToken;

  Future<void> initialize() {
    _initializationFuture ??= _initializeInternal();
    return _initializationFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
          debugPrint('FirebaseService: Initialized via native configuration.');
        } catch (nativeError) {
          debugPrint('FirebaseService: Native init failed ($nativeError), trying dynamic options...');
          await _tryDynamicInitialize();
        }
      } else {
        debugPrint('FirebaseService: Firebase already initialized.');
      }

      await _setupMessaging();
    } catch (e) {
      debugPrint('FirebaseService: Failed to initialize: $e');
    }
  }

  Future<void> _tryDynamicInitialize() async {
    try {
      final response = await _dioClient.dio.get('/platform-settings').timeout(
        const Duration(seconds: 5),
        onTimeout: () => Response(data: [], requestOptions: RequestOptions(path: '')),
      );
      final List settings = response.data is List ? response.data : [];
      String? find(String key) {
        try {
          final setting = settings.firstWhere((s) => s['key'] == key, orElse: () => null);
          return setting?['value'];
        } catch (_) {
          return null;
        }
      }

      final apiKey = find('FIREBASE_API_KEY');
      final messagingSenderId = find('FIREBASE_MESSAGING_SENDER_ID');
      final projectId = find('FIREBASE_PROJECT_ID');
      final storageBucket = find('FIREBASE_STORAGE_BUCKET');
      final authDomain = find('FIREBASE_AUTH_DOMAIN');

      String? appId;
      if (defaultTargetPlatform == TargetPlatform.android) {
        appId = find('FIREBASE_APP_ID_ANDROID') ?? find('FIREBASE_APP_ID');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        appId = find('FIREBASE_APP_ID_IOS') ?? find('FIREBASE_APP_ID');
      } else {
        appId = find('FIREBASE_APP_ID');
      }

      if (apiKey != null && appId != null && projectId != null) {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: FirebaseOptions(
              apiKey: apiKey.trim(),
              appId: appId.trim(),
              messagingSenderId: messagingSenderId?.trim() ?? '0',
              projectId: projectId.trim(),
              storageBucket: storageBucket?.trim(),
              authDomain: authDomain?.trim(),
              iosBundleId: defaultTargetPlatform == TargetPlatform.iOS ? 'com.nzubia.global' : null,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('FirebaseService: Dynamic initialize error: $e');
    }
  }

  Future<void> _setupMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FirebaseService: Notification permission status: ${settings.authorizationStatus}');

      // Setup local notifications for Android & iOS foreground heads-up display
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              _handleNotificationClick(data);
            } catch (_) {}
          }
        },
      );

      // Create Android High Importance Notification Channel for heads-up alerts
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Set presentation options for iOS foreground notifications
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('FirebaseService: Fetched FCM Token: $_fcmToken');
        await syncDeviceToken(_fcmToken!);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FirebaseService: FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        syncDeviceToken(newToken);
      });

      // Handle notification when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FirebaseService: onMessageOpenedApp received: ${message.data}');
        _handleNotificationClick(message.data);
      });

      // Handle notification when app opened from terminated state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FirebaseService: getInitialMessage received: ${initialMessage.data}');
        _handleNotificationClick(initialMessage.data);
      }

      // Foreground message listener: save in-app AND trigger heads-up popup banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FirebaseService: Foreground message received: ${message.notification?.title}');
        final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Notification';
        final body = message.notification?.body ?? message.data['body']?.toString() ?? message.data['message']?.toString() ?? '';
        final type = message.data['type']?.toString() ?? 'SYSTEM';
        final entityId = message.data['entity_id']?.toString() ?? message.data['shipment_id']?.toString() ?? '';
        if (title.isNotEmpty || body.isNotEmpty) {
          NotificationsBloc.savePushNotification(
            title: title,
            message: body,
            type: type,
            relatedEntityId: entityId,
          );

          // Show heads-up notification with sound and banner
          _localNotifications.show(
            id: message.hashCode,
            title: title,
            body: body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/launcher_icon',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });
    } catch (e) {
      debugPrint('FirebaseService: Error setting up messaging: $e');
    }
  }

  Future<void> syncDeviceToken([String? token]) async {
    final tokenToSend = token ?? _fcmToken;
    if (tokenToSend == null || tokenToSend.isEmpty) return;
    _fcmToken = tokenToSend;

    try {
      // 1. Primary: dedicated endpoint PATCH /users/device-token
      await _dioClient.dio.patch(
        ApiConstants.deviceToken,
        data: {'device_token': tokenToSend},
      );
      debugPrint('FirebaseService: Device token synced to ${ApiConstants.deviceToken}');
    } catch (e) {
      debugPrint('FirebaseService: Notice from ${ApiConstants.deviceToken}: $e. Attempting fallback sync via ${ApiConstants.profile}...');
      try {
        // 2. Fallback: PATCH /users/profile also directly persists device_token in users table
        await _dioClient.dio.patch(
          ApiConstants.profile,
          data: {'device_token': tokenToSend},
        );
        debugPrint('FirebaseService: Device token synced via fallback ${ApiConstants.profile}');
      } catch (e2) {
        debugPrint('FirebaseService: Error syncing fallback device token: $e2');
      }
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('FirebaseService: Handling notification click: $data');
    final type = data['type']?.toString();
    final shipmentId = (data['shipmentId'] ?? data['shipment_id'] ?? data['id'])?.toString();

    if ((type == 'P2P_SHIPMENT_REQUEST' || type == 'SHIPMENT_REQUEST_CREATED') && shipmentId != null && shipmentId.isNotEmpty) {
      AppRouter.router.push('/p2p/shipment/$shipmentId');
    } else if (shipmentId != null && shipmentId.isNotEmpty) {
      AppRouter.router.push('/p2p/shipment/$shipmentId');
    }
  }
}
