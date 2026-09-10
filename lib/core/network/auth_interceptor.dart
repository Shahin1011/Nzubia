import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_nzubia_global/config/routes/app_router.dart';
import 'package:customer_nzubia_global/core/constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      if (kDebugMode) debugPrint('AuthInterceptor: Attaching token...');
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      final devToken = ApiConstants.devAccessToken;
      if (devToken.isNotEmpty) {
        if (kDebugMode) debugPrint('AuthInterceptor: Using DEV_ACCESS_TOKEN fallback...');
        options.headers['Authorization'] = 'Bearer $devToken';
      } else {
        if (kDebugMode) debugPrint('AuthInterceptor: No token found in storage!');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      // Do not force logout on specific auth routes that might return 401 on purpose (e.g. invalid OTP)
      if (!path.contains('/auth/verify-otp') && !path.contains('/auth/reset-password')) {
        await _storage.delete(key: 'accessToken');
        final context = AppRouter.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          GoRouter.of(context).go('/login');
        }
      }
    }
    super.onError(err, handler);
  }
}
