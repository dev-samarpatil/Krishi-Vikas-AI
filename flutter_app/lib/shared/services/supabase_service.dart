import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

/// Provides the Supabase client instance for direct DB/auth operations.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseClientService.instance.client;
});

/// Provides the current auth session (nullable).
final authSessionProvider = Provider<Session?>((ref) {
  return SupabaseClientService.instance.client.auth.currentSession;
});

/// Stream of auth state changes for reactive UI updates.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return SupabaseClientService.instance.client.auth.onAuthStateChange;
});
