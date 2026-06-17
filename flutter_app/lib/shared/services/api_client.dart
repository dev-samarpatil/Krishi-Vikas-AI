import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../providers/auth_state_provider.dart';

/// Dio HTTP client configured with auth interceptor and retry logic.
/// All backend API calls go through this client.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 90),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Bypass-Tunnel-Reminder': 'true',
      },
    ),
  );

  // Auth interceptor — injects Supabase JWT on every request
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle 401 — token expired
        if (error.response?.statusCode == 401) {
          ref.read(authStateProvider.notifier).expireSession('Session expired. Please log in again.');
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
