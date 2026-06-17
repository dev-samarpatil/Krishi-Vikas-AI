import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';

import '../../../../l10n/app_localizations.dart';

class ScanLoadingScreen extends ConsumerStatefulWidget {
  const ScanLoadingScreen({super.key});

  @override
  ConsumerState<ScanLoadingScreen> createState() => _ScanLoadingScreenState();
}

class _ScanLoadingScreenState extends ConsumerState<ScanLoadingScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Listen for state changes
    ref.listen<ScanState>(scanProvider, (previous, next) {
      if (next.status == ScanStatus.success) {
        // Navigate to result
        context.pushReplacement(AppRoutes.scanResult);
      } else if (next.status == ScanStatus.error) {
        // We stay on this screen but show error UI, or handle error route.
        // For simplicity, we just stay here and show the error card.
      }
    });

    final scanState = ref.watch(scanProvider);
    
    // Navigation is handled by ref.listen above.

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Center(
            child: scanState.status == ScanStatus.error
                ? _buildErrorUI(scanState.errorMessage ?? l10n.couldNotAnalyse)
                : _buildLoadingUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.analysingCrop,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Connecting to agricultural intelligence engine',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorUI(String message) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 72, color: AppTheme.errorRed),
        const SizedBox(height: 24),
        Text(
          l10n.analysisFailed,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(scanProvider.notifier).runScan();
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retryAnalysis),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            context.go(AppRoutes.home);
          },
          child: Text(l10n.goHome),
        ),
      ],
    );
  }
}
