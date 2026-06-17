import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { authenticated, unauthenticated, sessionExpired }

class AuthState {
  final AuthStatus status;
  final String? message;
  final User? user;

  AuthState({required this.status, this.message, this.user});
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier()
      : super(AuthState(
          status: Supabase.instance.client.auth.currentSession != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          user: Supabase.instance.client.auth.currentUser,
        )) {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      if (session != null) {
        state = AuthState(status: AuthStatus.authenticated, user: session.user);
      } else {
        if (event == AuthChangeEvent.tokenRefreshed) {
          // Token refreshed successfully
        } else if (event == AuthChangeEvent.signedOut) {
          state = AuthState(status: AuthStatus.unauthenticated);
        } else {
          state = AuthState(status: AuthStatus.unauthenticated);
        }
      }
    });
  }

  void expireSession(String message) {
    state = AuthState(status: AuthStatus.sessionExpired, message: message);
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
