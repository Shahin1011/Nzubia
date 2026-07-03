import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';
import 'package:customer_nzubia_global/core/network/dio_client.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final DioClient _dioClient;
  static Future<void>? _initializationFuture;

  FirebaseService(this._dioClient);

  Future<void> initialize() {
    _initializationFuture ??= _initializeInternal();
    return _initializationFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      // If Firebase is already configured by another code path, do not configure again.
      if (Firebase.apps.isNotEmpty) {
        debugPrint('FirebaseService: Already initialized (apps list check passed).');
        return;
      }
      try {
        Firebase.app();
        debugPrint('FirebaseService: Already initialized (native app check passed).');
        return;
      } catch (_) {
        // Continue with dynamic initialization.
      }

      debugPrint('FirebaseService: Attempting to fetch configuration...');
      
      // 1. Fetch settings from backend with a timeout
      final response = await _dioClient.dio.get('/platform-settings').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('FirebaseService: Backend fetch timed out. Skipping dynamic config.');
          return Response(data: [], requestOptions: RequestOptions(path: ''));
        },
      );
      
      final List settings = response.data is List ? response.data : [];
      
      String? find(String key) {
        try {
          final setting = settings.firstWhere(
              (s) => s['key'] == key, 
              orElse: () => null
          );
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

      // Use platform-specific App IDs if available
      String? appId;
      if (defaultTargetPlatform == TargetPlatform.android) {
        appId = find('FIREBASE_APP_ID_ANDROID') ?? find('FIREBASE_APP_ID');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        appId = find('FIREBASE_APP_ID_IOS') ?? find('FIREBASE_APP_ID');
      } else {
        appId = find('FIREBASE_APP_ID');
      }
      
      bool isValid(String? val) => val != null && val.trim().isNotEmpty;
      bool isLikelyValidFirebaseAppId(String value) {
        final normalized = value.trim();
        final iosPattern = RegExp(r'^1:\d+:ios:[0-9a-fA-F]{8,}$');
        final androidPattern = RegExp(r'^1:\d+:android:[0-9a-fA-F]{8,}$');
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return iosPattern.hasMatch(normalized);
        }
        if (defaultTargetPlatform == TargetPlatform.android) {
          return androidPattern.hasMatch(normalized);
        }
        return normalized.startsWith('1:');
      }

      final appIdIsValid = isValid(appId) && isLikelyValidFirebaseAppId(appId!);

      if (isValid(apiKey) && appIdIsValid && isValid(projectId)) {
          // Re-check right before configure to avoid duplicate-app races.
          if (Firebase.apps.isNotEmpty) {
            debugPrint('FirebaseService: Already initialized (pre-configure check passed).');
            return;
          }

          try {
            await Firebase.initializeApp(
              options: FirebaseOptions(
                  apiKey: apiKey!.trim(),
                  appId: appId.trim(),
                  messagingSenderId: messagingSenderId?.trim() ?? '0', // Use '0' as safe fallback if missing
                  projectId: projectId!.trim(),
                  storageBucket: isValid(storageBucket) ? storageBucket!.trim() : null,
                  authDomain: isValid(authDomain) ? authDomain!.trim() : null,
                  iosBundleId: defaultTargetPlatform == TargetPlatform.iOS ? 'com.nzubia.global' : null,
              ),
            );
            debugPrint('FirebaseService: Initialized successfully for $defaultTargetPlatform');
          } catch (e) {
            final message = e.toString().toLowerCase();
            final isDuplicateApp = message.contains('duplicate-app') || message.contains('already exists');
            if (isDuplicateApp) {
              debugPrint('FirebaseService: Duplicate init avoided: $e');
              return;
            }
            rethrow;
          }
      } else {
        debugPrint('FirebaseService: Configuration invalid or missing (apiKey: ${isValid(apiKey)}, appId: $appIdIsValid, projectId: ${isValid(projectId)}). Skipping.');
      }

    } catch (e) {
      debugPrint('FirebaseService: Failed to initialize: $e');
    }
  }
}
