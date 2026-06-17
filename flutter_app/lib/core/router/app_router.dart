import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/farm_model.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_auth_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/farm/presentation/screens/my_farm_screen.dart';
import '../../features/farm/presentation/screens/farm_setup_screen.dart';
import '../../features/farm/presentation/screens/farm_detail_screen.dart';
import '../../features/scan/presentation/screens/scan_camera_screen.dart';
import '../../features/scan/presentation/screens/scan_preview_screen.dart';
import '../../features/scan/presentation/screens/scan_loading_screen.dart';
import '../../features/scan/presentation/screens/scan_result_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/map/presentation/screens/sentinel_map_screen.dart';
import '../../features/mandi/presentation/screens/mandi_prices_screen.dart';
import '../../features/schemes/presentation/screens/schemes_screen.dart';
import '../../features/schemes/presentation/screens/scheme_detail_screen.dart';
import '../../features/soil/presentation/screens/soil_health_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';
import '../../features/home/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';

/// Route name constants to avoid magic strings.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String phoneAuth = '/phone-auth';
  static const String farmSetup = '/farm-setup';

  // Shell (bottom nav) routes
  static const String home = '/home';
  static const String map = '/map';
  static const String scan = '/scan';
  static const String scanCamera = '/scan-camera';
  static const String chat = '/chat';
  static const String myFarm = '/my-farm';

  // Detail routes
  static const String scanResult = '/scan-result';
  static const String scanPreview = '/scan/preview';
  static const String scanLoading = '/scan/loading';
  static const String farmDetail = '/farm/:farmId';
  static const String mandiPrices = '/mandi-prices';
  static const String schemes = '/schemes';
  static const String schemeDetail = '/schemes/:schemeId';
  static const String soilHealth = '/soil-health/:farmId';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String weatherDetail = '/weather-detail';
}

// Navigation key for nested navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter provider — reactive to auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // ── Pre-Auth Routes ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmSetup,
        builder: (context, state) {
          final farm = state.extra as FarmModel?;
          return FarmSetupScreen(farmToEdit: farm);
        },
      ),

      // ── Main Shell (Bottom Navigation) ────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.map,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SentinelMapScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.scan,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScanCameraScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.myFarm,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyFarmScreen(),
            ),
          ),
        ],
      ),

      // ── Detail Routes (outside shell) ─────────────────────────────
      GoRoute(
        path: AppRoutes.scanResult,
        builder: (context, state) => const ScanResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanPreview,
        builder: (context, state) => const ScanPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.scanLoading,
        builder: (context, state) => const ScanLoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmDetail,
        builder: (context, state) {
          final farmId = state.pathParameters['farmId']!;
          return FarmDetailScreen(farmId: farmId);
        },
      ),
      GoRoute(
        path: AppRoutes.mandiPrices,
        builder: (context, state) => const MandiPricesScreen(),
      ),
      GoRoute(
        path: AppRoutes.schemes,
        builder: (context, state) => const SchemesScreen(),
      ),
      GoRoute(
        path: AppRoutes.schemeDetail,
        builder: (context, state) {
          final schemeId = state.pathParameters['schemeId']!;
          return SchemeDetailScreen(schemeId: schemeId);
        },
      ),
      GoRoute(
        path: AppRoutes.soilHealth,
        builder: (context, state) {
          final farmId = state.pathParameters['farmId']!;
          return SoilHealthScreen(farmId: farmId);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],

    // Redirect logic for auth guard
    redirect: (context, state) {
      // TODO: Implement auth state check with Riverpod
      // final isLoggedIn = ref.read(authProvider).isLoggedIn;
      // final isAuthRoute = state.matchedLocation == AppRoutes.splash
      //     || state.matchedLocation == AppRoutes.phoneAuth;
      // if (!isLoggedIn && !isAuthRoute) return AppRoutes.phoneAuth;
      return null;
    },
  );
});
