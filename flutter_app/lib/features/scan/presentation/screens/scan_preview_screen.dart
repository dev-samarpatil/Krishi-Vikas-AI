import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';

import '../../../../l10n/app_localizations.dart';

class ScanPreviewScreen extends ConsumerWidget {
  const ScanPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanProvider);
    final imageFile = scanState.imageFile;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.confirmPhoto, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: imageFile != null
                ? InteractiveViewer(
                    child: kIsWeb
                        ? Image.network(
                            imageFile.path,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(imageFile.path),
                            fit: BoxFit.contain,
                          ),
                  )
                : const Center(
                    child: Text('No image selected', style: TextStyle(color: Colors.white70)),
                  ),
          ),
          Container(
            color: Colors.black.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.retake),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: ElevatedButton(
                    onPressed: imageFile == null
                        ? null
                        : () {
                            // Trigger the scan
                            ref.read(scanProvider.notifier).runScan();
                            // Route to loading screen
                            context.push(AppRoutes.scanLoading);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(l10n.useThisPhoto),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
