import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:customer_nzubia_global/config/routes/app_router.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  void initialize() {
    // Check initial link if app was closed
    _checkInitialLink();

    // Listen to incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      if (kDebugMode) {
        if (kDebugMode) debugPrint('Deep Link Error: $err');
      }
    });
  }

  Future<void> _checkInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) debugPrint('Initial Link Error: $e');
      }
    }
  }

  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      if (kDebugMode) debugPrint('Handling Deep Link: $uri');
    }

    // Example: nzubia://shipment/123
    // Example: nzubia://chat/abc
    
    if (uri.scheme == 'nzubia' || (uri.host == 'nzubia.com')) {
      if (uri.path.contains('payment-success') || uri.path.contains('success')) {
        AppRouter.router.push('/payment/success');
      } else if (uri.path.contains('payment-cancel') || uri.path.contains('cancel')) {
        AppRouter.router.push('/payment/cancel');
      } else if (uri.path.startsWith('/shipment/') || uri.host == 'shipment') {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.path.replaceAll('/', '');
        AppRouter.router.push('/shipment/$id');
      } else if (uri.path.startsWith('/chat/') || uri.host == 'chat') {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.path.replaceAll('/', '');
        AppRouter.router.push('/chat/$id');
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
