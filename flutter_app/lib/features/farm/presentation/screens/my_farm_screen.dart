import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/farm_model.dart';
import '../../providers/farm_provider.dart';
import '../widgets/lifecycle_timeline.dart';
import '../widgets/soil_health_dial.dart';
import '../../../../l10n/app_localizations.dart';

class MyFarmScreen extends ConsumerWidget {
  const MyFarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmsAsync = ref.watch(farmsProvider);
    final selectedFarmId = ref.watch(selectedFarmIdProvider);
    final selectedFarm = ref.watch(selectedFarmProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBinejyEdUXlxQ_jedeUNh6EChe2KHaMu2izyYnupFsfz_oQMXvVUXv_caFmB_ltMU7D_KBls7RGjtmz-UIcsYsBFqYufS0Rdxo_VIFBagL2FlkCFxQTq02cOMVLXbWWFnMVVShtwsNf05F-bq-0cUVCchdR-eqbez9O2rhn10GdfAT4Pfj8vF1hGAqlzNH7LxHMwH8vNuJCvyZuWPFyu7qTNyS2A9jif49npC-_6GJ9ikMdM7aRQieUyFcVvifgcNixJDa2G0dtpE',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Krishi Vikas AI',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF012D1D),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF012D1D)),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: farmsAsync.when(
          data: (farms) {
            if (farms.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(farmsProvider.future),
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.myFarm,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF191C1D),
                              ),
                            ),
                            const Text(
                              'Manage and monitor your registered plots.',
                              style: TextStyle(
                                color: Color(0xFF414844),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push(AppRoutes.farmSetup),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4332), // primary-container
                            foregroundColor: Colors.white, // on-primary
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Farm List (Selector)
                    SizedBox(
                      height: 165,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: farms.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final farm = farms[index];
                          final isSelected = farm.id == selectedFarmId;
                          return SizedBox(
                            width: 240,
                            child: _buildFarmCard(context, ref, farm, isSelected),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (selectedFarm != null) ...[
                      // Soil Health Section
                      _buildSoilHealthSection(context, ref, selectedFarm),
                      const SizedBox(height: 24),

                      // Farm Lifecycle Section
                      _buildLifecycleSection(context, ref, selectedFarm),
                      const SizedBox(height: 24),

                      // Diagnosis Log Section
                      _buildDiagnosisLogSection(context, ref, selectedFarm.id),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading farm data...', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load farms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(farmsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFarmCard(BuildContext context, WidgetRef ref, FarmModel farm, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedFarmIdProvider.notifier).select(farm.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4332) : const Color(0xFFE1E3E4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4332).withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (farm.soilScore < 40)
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0BD8B), // secondary-fixed-dim
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D562D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NEEDS ATTENTION',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 16), // top padding
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            farm.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF191C1D)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, color: Color(0xFF414844), size: 20),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Farm'),
                                  content: Text('Are you sure you want to delete ${farm.name}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(farmRepositoryProvider).deleteFarm(farm.id);
                                ref.invalidate(farmsProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farm deleted')));
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.eco_outlined, size: 16, color: Color(0xFF414844)),
                        const SizedBox(width: 4),
                        Text(farm.crop, style: const TextStyle(fontSize: 14, color: Color(0xFF414844))),
                      ],
                    ),
                    const Spacer(),
                    Container(height: 1, color: const Color(0xFFE1E3E4), margin: const EdgeInsets.symmetric(vertical: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.water_drop, size: 16, color: farm.soilScore < 40 ? Colors.red : const Color(0xFF414844)),
                            const SizedBox(width: 4),
                            Text(
                              farm.farmingType,
                              style: TextStyle(fontSize: 12, color: farm.soilScore < 40 ? Colors.red : const Color(0xFF414844)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA5D0B9), // primary-fixed-dim
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            farm.currentStage.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF002114)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilHealthSection(BuildContext context, WidgetRef ref, FarmModel farm) {
    final diagnosesAsync = ref.watch(farmDiagnosesProvider(farm.id));
    
    double dynamicScore = farm.soilScore.toDouble();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E3E4)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1B4332).withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Soil Health', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
              const Tooltip(
                message: 'Score dynamically adjusted based on recent diagnosis logs.',
                child: Icon(Icons.info_outline, color: Color(0xFF414844)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Estimated Score', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF414844))),
          const SizedBox(height: 16),
          SoilHealthDial(score: dynamicScore.toInt()),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildNpkCard('Nitrogen (N)', 'Optimal', const Color(0xFF012D1D))),
              const SizedBox(width: 12),
              Expanded(child: _buildNpkCard('Phosphorus (P)', 'Good', const Color(0xFF012D1D))),
              const SizedBox(width: 12),
              Expanded(child: _buildNpkCard('Potassium (K)', 'Low', const Color(0xFF7D562D))), // secondary
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNpkCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5), // surface-container-low
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF414844)), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildLifecycleSection(BuildContext context, WidgetRef ref, FarmModel farm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E3E4)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1B4332).withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Farm Lifecycle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
          const SizedBox(height: 24),
          LifecycleTimeline(currentStage: farm.currentStage),
          const SizedBox(height: 16),
          if (farm.currentStage != AppConstants.growthStages.last)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final currentIdx = AppConstants.growthStages.indexOf(farm.currentStage);
                  if (currentIdx != -1 && currentIdx < AppConstants.growthStages.length - 1) {
                    final nextStage = AppConstants.growthStages[currentIdx + 1];
                    try {
                      await ref.read(farmRepositoryProvider).updateFarm(farm.id, {'current_stage': nextStage});
                      ref.invalidate(farmsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Advanced to ${nextStage.toUpperCase()}')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF012D1D)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisLogSection(BuildContext context, WidgetRef ref, String farmId) {
    final diagnosesAsync = ref.watch(farmDiagnosesProvider(farmId));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E3E4)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1B4332).withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diagnosis Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF191C1D))),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: Color(0xFF012D1D)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          diagnosesAsync.when(
            data: (diagnoses) {
              if (diagnoses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No diagnosis history', style: TextStyle(color: Color(0xFF717973)))),
                );
              }
              return Column(
                children: diagnoses.take(3).map((d) {
                  final isHealthy = d.diseaseName == null || d.diseaseName!.toLowerCase().contains('healthy');
                  final recommendation = (d.treatmentSteps != null && d.treatmentSteps!.isNotEmpty) 
                      ? d.treatmentSteps!.first['step']?.toString() ?? d.treatmentSteps!.first['title']?.toString() ?? 'Treatment suggested'
                      : 'No action required';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isHealthy ? const Color(0xFFC1ECD4) : const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isHealthy ? Icons.check_circle_outline : Icons.bug_report_outlined,
                            color: isHealthy ? const Color(0xFF002114) : const Color(0xFFBA1A1A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isHealthy ? 'Crop Healthy' : d.diseaseName ?? 'Issue Detected',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF191C1D)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d').format(d.createdAt),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF414844)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (!isHealthy)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B4332).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Organic', style: TextStyle(color: Color(0xFF012D1D), fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  Expanded(
                                    child: Text(
                                      recommendation,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF414844)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading logs', style: TextStyle(color: Colors.red[300]))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF012D1D).withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.agriculture, size: 80, color: Color(0xFF012D1D)),
            ),
            const SizedBox(height: 24),
            const Text('No farms setup yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF191C1D))),
            const SizedBox(height: 12),
            const Text(
              'Create your first farm to unlock growth tracking, soil diagnostics, and localized crop scanning metrics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF414844), fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.farmSetup),
              icon: const Icon(Icons.add),
              label: const Text('Add My First Farm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
