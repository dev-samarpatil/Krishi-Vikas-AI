import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

enum ConnectivityStatus { isConnected, isDisconnected }

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  ConnectivityNotifier() : super(ConnectivityStatus.isConnected) {
    _init();
  }

  void _init() async {
    final results = await _connectivity.checkConnectivity();
    await _updateStatus(results);
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });
  }

  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      state = ConnectivityStatus.isDisconnected;
      return;
    }
    
    // Perform a quick ping check to make sure there's real internet access
    try {
      final pingUrl = kIsWeb ? '${AppConstants.baseUrl}/api/health' : 'https://www.google.com';
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      final response = await dio.get(pingUrl);
      if (response.statusCode == 200) {
        state = ConnectivityStatus.isConnected;
      } else {
        state = ConnectivityStatus.isDisconnected;
      }
    } catch (_) {
      state = ConnectivityStatus.isDisconnected;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
