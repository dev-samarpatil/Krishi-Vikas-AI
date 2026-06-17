import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dio/dio.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/supabase_client.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:krishi_vikas_ai/l10n/app_localizations.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/auth_state_provider.dart';
import 'shared/services/push_notification_service.dart';
import 'shared/services/api_client.dart';

import 'package:flutter/foundation.dart'; // Added for kIsWeb

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }

  // Initialize Hive (local storage)
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.cacheBox);

  // Initialize Firebase correctly based on platform
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCQeKw4BZkpO1TiBqbRg4q9qhmfDdnfD8E",
          authDomain: "krishivikasai.firebaseapp.com",
          projectId: "krishivikasai",
          storageBucket: "krishivikasai.firebasestorage.app",
          messagingSenderId: "873782360989",
          appId: "1:873782360989:web:560268b2a15306429a8d74",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  // Initialize Supabase Client Service
  try {
    await SupabaseClientService.instance.init();
  } catch (e) {
    debugPrint("Supabase init failed: $e");
  }

  runApp(
    const ProviderScope(
      child: KrishiVikasApp(),
    ),
  );
}

class KrishiVikasApp extends ConsumerStatefulWidget {
  const KrishiVikasApp({super.key});

  @override
  ConsumerState<KrishiVikasApp> createState() => _KrishiVikasAppState();
}

class _KrishiVikasAppState extends ConsumerState<KrishiVikasApp> {
  @override
  void initState() {
    super.initState();
    // Initialize push notifications after widget binding is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dio = ref.read(dioProvider);
      PushNotificationService.init(dio);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    // Listen to session expired auth states and prompt user / redirect
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.sessionExpired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Session Expired'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        router.go(AppRoutes.onboarding);
      }
    });

    return MaterialApp.router(
      title: 'Krishi Vikas AI',
      debugShowCheckedModeBanner: false,
      locale: locale,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Routing
      routerConfig: router,

      // Localization — supports EN, HI, MR, TA
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppConstants.supportedLocales,
    );
  }
}

