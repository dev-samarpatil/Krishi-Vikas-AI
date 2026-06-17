import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton wrapper for Supabase client.
class SupabaseClientService {
  SupabaseClientService._privateConstructor();
  static final SupabaseClientService instance = SupabaseClientService._privateConstructor();

  SupabaseClient? _client;

  /// Retrieves the initialized Supabase client. 
  /// Throws an error if used before `init()` is called.
  SupabaseClient get client {
    if (_client == null) {
      throw Exception('SupabaseClientService not initialized. Call init() first.');
    }
    return _client!;
  }

  /// Initializes the Supabase client using environment variables.
  Future<void> init() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file.');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    _client = Supabase.instance.client;
  }
}
