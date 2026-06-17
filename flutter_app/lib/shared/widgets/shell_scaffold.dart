import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../providers/connectivity_provider.dart';

/// Bottom navigation shell — wraps the 5 main tabs.
/// Centre tab (Scan) uses a raised FAB-style button per App Flow doc.
class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  static const _tabs = [
    AppRoutes.home,
    AppRoutes.map,
    AppRoutes.scan,
    AppRoutes.chat,
    AppRoutes.myFarm,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexOf(location);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final l10n = AppLocalizations.of(context);
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity == ConnectivityStatus.isDisconnected;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (isOffline)
              Container(
                width: double.infinity,
                color: AppTheme.errorRed,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l10n?.noConnection ?? 'No connection — showing cached data',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index != currentIndex) {
              context.go(_tabs[index]);
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n?.home ?? 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: l10n?.map ?? 'Map',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.camera_alt_outlined),
              activeIcon: const Icon(Icons.camera_alt),
              label: l10n?.scan ?? 'Scan',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_outlined),
              activeIcon: const Icon(Icons.chat),
              label: l10n?.chat ?? 'Chat',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.agriculture_outlined),
              activeIcon: const Icon(Icons.agriculture),
              label: l10n?.myFarm ?? 'My Farm',
            ),
          ],
        ),
      ),
    );
  }
}
