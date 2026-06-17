import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:krishi_vikas_ai/l10n/app_localizations.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/mandi_price_model.dart';
import '../../../../shared/models/farm_model.dart';
import '../../../../shared/providers/locale_provider.dart';
import '../../../farm/providers/farm_provider.dart';
import '../providers/weather_provider.dart';
import '../../mandi/providers/mandi_provider.dart';
import '../providers/alert_provider.dart';

/// Home screen — dashboard showing weather, alerts, scan CTA, and mandi prices.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFarm = ref.watch(selectedFarmProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed top app bar
            _buildTopAppBar(context, ref, selectedFarm),
            // Scrollable content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(weatherProvider);
                  ref.invalidate(mandiProvider);
                  ref.invalidate(alertProvider);
                },
                color: AppTheme.primaryGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                    96,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Farm profile strip
                      _buildProfileStrip(context, selectedFarm),
                      const SizedBox(height: AppTheme.spacingMd),

                      // 2. Weather Card
                      _buildWeatherWidget(context, ref),
                      const SizedBox(height: AppTheme.spacingMd),

                      // 3. Quick Actions
                      _buildQuickActions(context, selectedFarm),
                      const SizedBox(height: AppTheme.spacingMd),

                      // 4. Scan Hero Card
                      _buildScanHeroCard(context, selectedFarm),
                      const SizedBox(height: AppTheme.spacingMd),

                      // 5. Recent Alerts
                      _buildRecentAlerts(ref, context),
                      const SizedBox(height: AppTheme.spacingMd),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, WidgetRef ref, FarmModel? farm) {
    final currentLocale = ref.watch(localeProvider);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D1B4332),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Krishi Vikas AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
              ),
            ],
          ),
          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: () => _showLanguageDialog(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language, color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        currentLocale.languageCode.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, ref, 'en', 'English'),
              _buildLanguageOption(context, ref, 'hi', 'हिन्दी (Hindi)'),
              _buildLanguageOption(context, ref, 'mr', 'मराठी (Marathi)'),
              _buildLanguageOption(context, ref, 'ta', 'தமிழ் (Tamil)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, String code, String name) {
    return ListTile(
      title: Text(name),
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  Widget _buildProfileStrip(BuildContext context, FarmModel? farm) {
    if (farm == null) return const SizedBox.shrink();

    final cropStr = farm.crop[0].toUpperCase() + farm.crop.substring(1);
    final locStr = farm.district ?? '';
    final sizeStr = '${farm.farmSize} acres';
    final stageStr = farm.currentStage[0].toUpperCase() + farm.currentStage.substring(1);

    return GestureDetector(
      onTap: () => context.go(AppRoutes.myFarm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(Icons.agriculture, color: AppTheme.primaryGreen, size: 24),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.eco, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(cropStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      if (locStr.isNotEmpty) ...[
                        const Text('  •  ', style: TextStyle(color: AppTheme.textHint)),
                        const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(locStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    stageStr,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(sizeStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAlerts(WidgetRef ref, BuildContext context) {
    final alertsAsync = ref.watch(alertProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.map),
                  child: const Text('View All',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ...alerts.take(2).map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 22),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alert.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary)),
                              if (alert.message.isNotEmpty)
                                Text(alert.message,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(BuildContext context, FarmModel? farm) {
    final actions = [
      {'icon': Icons.currency_rupee, 'label': 'Mandi\nPrices', 'color': AppTheme.primaryGreen, 'bg': AppTheme.primaryLight, 'route': AppRoutes.mandiPrices},
      {'icon': Icons.description_outlined, 'label': 'Gov\nSchemes', 'color': AppTheme.accentOrange, 'bg': AppTheme.accentAmber, 'route': AppRoutes.schemes},
      {'icon': Icons.eco_outlined, 'label': 'Soil\nHealth', 'color': AppTheme.successGreen, 'bg': const Color(0xFFA1F4C8), 'route': '/soil-health/${farm?.id ?? '1'}'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: actions.indexOf(a) < 2 ? AppTheme.spacingSm : 0),
                child: GestureDetector(
                  onTap: () => context.push(a['route'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (a['bg'] as Color).withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 24),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          a['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeatherWidget(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    final selectedFarm = ref.watch(selectedFarmProvider);

    return weatherAsync.when(
      data: (weather) {
        if (weather == null) {
          return Consumer(
            builder: (context, ref, child) {
              final l10n = AppLocalizations.of(context)!;
              return _buildWeatherPlaceholder(l10n.noLocationData);
            },
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.dividerGray.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Weather',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      if (selectedFarm?.district != null)
                        Text(
                          '${selectedFarm!.district}, ${selectedFarm.state ?? ""}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                  Icon(
                    _getWeatherIconData(weather.condition),
                    color: AppTheme.accentOrange,
                    size: 36,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${weather.temp.round()}°C',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    weather.condition,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const Divider(height: AppTheme.spacingMd),
              Row(
                children: [
                  const Icon(Icons.water_drop_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('Humidity: ${weather.humidity?.round() ?? '--'}%',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(width: AppTheme.spacingMd),
                  const Icon(Icons.air, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('Wind: ${weather.windSpeed?.round() ?? '--'} km/h',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              if (weather.alert != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Color(0xFFF9A825), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(weather.alert!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFF9A825), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
              if (weather.forecast.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMd),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: weather.forecast.take(5).map((f) {
                      return Container(
                        margin: const EdgeInsets.only(right: AppTheme.spacingSm),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Column(
                          children: [
                            Text(DateFormat('E').format(f.date),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Icon(_getWeatherIconData(f.condition), size: 16, color: AppTheme.accentOrange),
                            const SizedBox(height: 4),
                            Text('${f.temp.round()}°',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => _buildWeatherSkeleton(),
      error: (err, _) => Consumer(
        builder: (context, ref, child) {
          final l10n = AppLocalizations.of(context)!;
          return _buildWeatherPlaceholder(l10n.couldNotLoadWeather);
        },
      ),
    );
  }

  IconData _getWeatherIconData(String condition) {
    if (condition.toLowerCase().contains('clear')) return Icons.sunny;
    if (condition.toLowerCase().contains('rain')) return Icons.water_drop;
    return Icons.cloud;
  }

  Widget _buildWeatherSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      ),
    );
  }

  Widget _buildWeatherPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.dividerGray.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildScanHeroCard(BuildContext context, FarmModel? farm) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.scan),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan Your Crop',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Detect diseases instantly using AI',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Scan Now',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryLight, size: 48),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketPrices(WidgetRef ref, BuildContext context) {
    final mandiAsync = ref.watch(mandiProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.marketPrices,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.mandiPrices),
              child: Text(l10n.seeAll, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        mandiAsync.when(
          data: (prices) {
            if (prices.isEmpty) {
              return Text(l10n.noPricesAvailable, style: const TextStyle(color: AppTheme.textSecondary));
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: prices.map((price) => _buildPriceCard(context, price)).toList(),
              ),
            );
          },
          loading: () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(3, (index) => _buildPriceSkeleton()),
            ),
          ),
          error: (err, _) => Text(l10n.couldNotLoadPrices, style: const TextStyle(color: AppTheme.errorRed)),
        ),
      ],
    );
  }

  Widget _buildPriceCard(BuildContext context, MandiPriceModel price) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.dividerGray.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getTranslatedCrop(context, price.crop), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            AppLocalizations.of(context)!.pricePerQuintal(price.price.toInt().toString()),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              Icon(
                price.isUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: price.isUp ? AppTheme.successGreen : AppTheme.errorRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 150,
        height: 100,
        margin: const EdgeInsets.only(right: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildGovernmentSchemes(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.schemes),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppTheme.accentAmber,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentAmber.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_outlined, color: AppTheme.accentOrange, size: 26),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.governmentSchemes,
                    style: const TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.viewDetailsApply,
                    style: TextStyle(
                      color: AppTheme.accentOrange.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.accentOrange, size: 18),
          ],
        ),
      ),
    );
  }
}

String _getTranslatedCrop(BuildContext context, String cropName) {
  final l10n = AppLocalizations.of(context)!;
  final lower = cropName.toLowerCase();
  if (lower.contains('tomato')) return l10n.cropTomato;
  if (lower.contains('onion')) return l10n.cropOnion;
  if (lower.contains('cotton')) return l10n.cropCotton;
  if (lower.contains('wheat')) return l10n.cropWheat;
  if (lower.contains('soybean')) return l10n.cropSoybean;
  if (lower.contains('rice')) return l10n.cropRice;
  if (lower.contains('potato')) return l10n.cropPotato;
  if (lower.contains('grapes')) return l10n.cropOther; // Missing grapes translation, fallback or add it
  return cropName;
}
