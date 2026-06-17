import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:io';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/kvk_model.dart';
import '../../../../shared/models/budget_item.dart';
import '../../../../shared/repositories/scan_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../farm/providers/farm_provider.dart';
import '../../models/scan_response_model.dart';
import '../providers/scan_provider.dart';

class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({super.key});

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSavingLog = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveToLog() async {
    final scanState = ref.read(scanProvider);
    final result = scanState.result;
    if (result == null) return;

    setState(() {
      _isSavingLog = true;
    });

    try {
      final treatmentType = _tabController.index == 0 ? 'organic' : 'chemical';
      final repo = ref.read(scanRepositoryProvider);
      final selectedFarm = ref.read(selectedFarmProvider);
      await repo.saveToFarmLog(
        diagnosisId: result.diagnosisId,
        treatmentType: treatmentType,
        diseaseName: result.diseaseName,
        crop: selectedFarm?.crop ?? 'Unknown Crop',
        farmId: selectedFarm?.id ?? '',
      );
      
      // Update soil score in local farms provider to trigger dynamic update
      ref.invalidate(farmsProvider);
      
      setState(() {
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully saved diagnosis and treatment choice to farm log!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to log: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingLog = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final result = scanState.result;
    final selectedFarm = ref.watch(selectedFarmProvider);
    final cropName = selectedFarm?.crop ?? 'Unknown Crop';
    final l10n = AppLocalizations.of(context)!;
    
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.diagnosisResult)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No diagnosis results found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.goHome),
              ),
            ],
          ),
        ),
      );
    }

    final kvksAsync = ref.watch(kvkListProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.diagnosisResult,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            onPressed: () {
              ref.read(scanProvider.notifier).reset();
              context.go(AppRoutes.home);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with gradient overlay
            _buildHeroSection(scanState, result, cropName, l10n),
            const SizedBox(height: AppTheme.spacingMd),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabs
                  _buildTreatmentTabs(result, l10n),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Cost table
                  _buildCostTable(result, l10n),
                  const SizedBox(height: AppTheme.spacingMd),

                  // KVK Section
                  kvksAsync.when(
                    data: (kvks) => kvks.isNotEmpty ? _buildKvkList(kvks, l10n) : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Save to log button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaved ? null : (_isSavingLog ? null : _saveToLog),
                      icon: _isSavingLog
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(_isSaved ? Icons.check : Icons.save_outlined),
                      label: Text(_isSaved ? 'Saved ✓' : (_isSavingLog ? 'Saving...' : l10n.saveToFarmLog)),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ScanState scanState, ScanResponseModel result, String cropName, AppLocalizations l10n) {
    return Stack(
      children: [
        // Background image
        Container(
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.12),
            image: scanState.imageFile != null
                ? DecorationImage(
                    image: FileImage(File(scanState.imageFile!.path)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: scanState.imageFile == null
              ? const Center(
                  child: Icon(Icons.eco, size: 64, color: AppTheme.primaryLight),
                )
              : null,
        ),
        // Gradient overlay
        Container(
          width: double.infinity,
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
              stops: [0.4, 1.0],
            ),
          ),
        ),
        // Content overlaid at bottom
        Positioned(
          bottom: 16,
          left: AppTheme.spacingMd,
          right: AppTheme.spacingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    ),
                    child: const Text(
                      'HIGH SEVERITY',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    ),
                    child: Text(
                      '${(result.confidence * 100).round()}% Match',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                result.diseaseName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentTabs(ScanResponseModel result, AppLocalizations l10n) {
    return Column(
      children: [
        // Tab row
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.dividerGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: l10n.organicTreatment),
              Tab(text: l10n.chemicalTreatment),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        // Tab content
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            final List<String> steps = _tabController.index == 0
                ? result.organicOption.steps
                : result.treatmentSteps;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tabController.index == 0
                      ? 'Immediate organic actions to control spread and restore plant health.'
                      : 'Chemical treatment options for rapid disease control.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                ...steps.asMap().entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCostTable(ScanResponseModel result, AppLocalizations l10n) {
    final budgetItems = result.budgetItems as List<BudgetItem>?;
    if (budgetItems == null || budgetItems.isEmpty) return const SizedBox.shrink();

    final total = budgetItems.fold<double>(0, (sum, b) => sum + b.priceInr);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated Material Cost',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              Text('Est. Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            ],
          ),
          const Divider(),
          ...budgetItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.item, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
                    Text('₹${item.priceInr.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('₹${total.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKvkList(List<KvkModel> kvks, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.warningYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Expert Help?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
          ),
          const SizedBox(height: 4),
          Text(
            'Consult your nearest Krishi Vigyan Kendra (KVK)',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...kvks.take(3).map((kvk) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kvk.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                        if (kvk.distance != null)
                          Text('${kvk.distance!.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final query = Uri.encodeComponent('${kvk.name} ${kvk.address ?? ""}');
                      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXLarge)),
                    ),
                    child: const Text('Directions', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
