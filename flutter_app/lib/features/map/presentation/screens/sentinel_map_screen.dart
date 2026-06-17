import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../farm/providers/farm_provider.dart';

class Outbreak {
  final String diseaseName;
  final String severity; // High, Medium, Low
  final LatLng location;
  final double distanceKm;
  final int caseCount;

  Outbreak({
    required this.diseaseName,
    required this.severity,
    required this.location,
    required this.distanceKm,
    required this.caseCount,
  });
}

/// Sentinel Map screen — disease outbreaks + climate risk overlays.
class SentinelMapScreen extends ConsumerStatefulWidget {
  const SentinelMapScreen({super.key});

  @override
  ConsumerState<SentinelMapScreen> createState() => _SentinelMapScreenState();
}

class _SentinelMapScreenState extends ConsumerState<SentinelMapScreen> {
  bool _showDiseaseOutbreak = true; // Toggle: Disease vs Climate
  String _activeWeatherLayer = 'clouds_new'; // clouds_new, temp_new, precipitation_new, wind_new
  Outbreak? _selectedOutbreak;
  List<Outbreak> _outbreaks = [];
  bool _outbreaksGenerated = false;

  // Weather toggle options
  final List<Map<String, String>> _weatherLayers = [
    {'id': 'clouds_new', 'label': 'Clouds'},
    {'id': 'temp_new', 'label': 'Temperature'},
    {'id': 'precipitation_new', 'label': 'Precipitation'},
    {'id': 'wind_new', 'label': 'Wind'},
  ];

  double _calculateDistance(LatLng p1, LatLng p2) {
    const r = 6371; // Earth radius in km
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180) *
            math.cos(p2.latitude * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  void _generateDemoOutbreaks(LatLng center) {
    if (_outbreaksGenerated) return;

    final List<Map<String, dynamic>> diseaseTemplates = [
      {'name': 'Fall Armyworm', 'severity': 'High', 'latOffset': 0.018, 'lngOffset': 0.022, 'cases': 14},
      {'name': 'Late Blight', 'severity': 'Medium', 'latOffset': -0.024, 'lngOffset': 0.018, 'cases': 8},
      {'name': 'Leaf Miner', 'severity': 'Low', 'latOffset': 0.031, 'lngOffset': -0.015, 'cases': 3},
      {'name': 'Stem Borer', 'severity': 'High', 'latOffset': -0.015, 'lngOffset': 0.035, 'cases': 19},
      {'name': 'Powdery Mildew', 'severity': 'Medium', 'latOffset': 0.028, 'lngOffset': 0.028, 'cases': 6},
    ];

    _outbreaks = diseaseTemplates.map((tmpl) {
      final loc = LatLng(
        center.latitude + (tmpl['latOffset'] as double),
        center.longitude + (tmpl['lngOffset'] as double),
      );
      final dist = _calculateDistance(center, loc);
      return Outbreak(
        diseaseName: tmpl['name'] as String,
        severity: tmpl['severity'] as String,
        location: loc,
        distanceKm: dist,
        caseCount: tmpl['cases'] as int,
      );
    }).toList();

    _outbreaksGenerated = true;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.errorRed;
      case 'medium':
        return const Color(0xFFFCAB28); // secondary-container amber
      case 'low':
      default:
        return const Color(0xFFC0C9BB); // outline-variant muted green
    }
  }

  double _getSeveritySize(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return 40;
      case 'medium': return 32;
      default: return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedFarm = ref.watch(selectedFarmProvider);
    final LatLng farmerLocation = LatLng(
      selectedFarm?.latWithFallback ?? 19.3919,
      selectedFarm?.lngWithFallback ?? 72.8397,
    );

    // Generate outbreaks around farmer's active coordinates
    _generateDemoOutbreaks(farmerLocation);

    final apiKey = AppConstants.openWeatherApiKey;
    final hasWeatherKey = apiKey.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // ── Light Map Base ──────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCenter: farmerLocation,
              initialZoom: 11,
              onTap: (_, __) => setState(() => _selectedOutbreak = null),
            ),
            children: [
              // Light-themed map tiles (CartoDB Voyager)
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'ai.krishivikas.app',
              ),

              // Climate Risk Overlays
              if (!_showDiseaseOutbreak && hasWeatherKey)
                Opacity(
                  opacity: 0.6,
                  child: TileLayer(
                    urlTemplate:
                        'https://tile.openweathermap.org/map/${_activeWeatherLayer}/{z}/{x}/{y}.png?appid=$apiKey',
                  ),
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // ── Pulsing Farmer Location ───────────────
                  Marker(
                    point: farmerLocation,
                    width: 48,
                    height: 48,
                    child: _PulsingLocationDot(),
                  ),

                  // ── Outbreak Markers ──────────────────────
                  if (_showDiseaseOutbreak)
                    ..._outbreaks.map((outbreak) {
                      final color = _getSeverityColor(outbreak.severity);
                      final size = _getSeveritySize(outbreak.severity);
                      final isLow = outbreak.severity.toLowerCase() == 'low';

                      if (isLow) {
                        // Small scattered dot for Low severity
                        return Marker(
                          point: outbreak.location,
                          width: size,
                          height: size,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedOutbreak = outbreak),
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: AppTheme.errorRed.withOpacity(0.6), blurRadius: 5),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      // Numbered cluster bubble for High/Medium
                      return Marker(
                        point: outbreak.location,
                        width: 140, // Expanded width to prevent text wrap overflow
                        height: size + 60, // Expanded height to accommodate text
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedOutbreak = outbreak),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                                  boxShadow: [
                                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 15),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${outbreak.caseCount}',
                                    style: TextStyle(
                                      color: outbreak.severity == 'High' ? Colors.white : const Color(0xFF694300),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              if (outbreak.severity == 'High') ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2F312F).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'High Risk Area',
                                    style: TextStyle(color: Color(0xFFF1F1EE), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // ── Top Toggle Pills ──────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2F312F).withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // Disease Outbreak pill
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _showDiseaseOutbreak = true;
                        _selectedOutbreak = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showDiseaseOutbreak ? AppTheme.errorRed : AppTheme.surfaceWhite.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _showDiseaseOutbreak
                              ? [BoxShadow(color: AppTheme.errorRed.withOpacity(0.3), blurRadius: 12)]
                              : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.coronavirus, size: 20, color: _showDiseaseOutbreak ? Colors.white : AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.diseaseOutbreak,
                              style: TextStyle(
                                color: _showDiseaseOutbreak ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Climate Risk pill
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _showDiseaseOutbreak = false;
                        _selectedOutbreak = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showDiseaseOutbreak ? const Color(0xFF2196F3) : AppTheme.surfaceWhite.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: !_showDiseaseOutbreak
                              ? [BoxShadow(color: const Color(0xFF2196F3).withOpacity(0.3), blurRadius: 12)]
                              : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.device_thermostat, size: 20, color: !_showDiseaseOutbreak ? Colors.white : AppTheme.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              l10n.climateRisk,
                              style: TextStyle(
                                color: !_showDiseaseOutbreak ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          // ── Bottom Overlays ───────────────────────────────
          if (_showDiseaseOutbreak && _selectedOutbreak != null)
            _buildOutbreakPopupCard(_selectedOutbreak!)
          else if (_showDiseaseOutbreak)
            _buildSurveillanceLegend()
          else if (!_showDiseaseOutbreak)
            _buildClimateRiskControls(hasWeatherKey),
        ],
      ),
    );
  }

  /// Regional Surveillance legend card at the bottom.
  Widget _buildSurveillanceLegend() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2F312F).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF717A6D).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.diseaseOutbreakAlerts.toUpperCase(),
              style: TextStyle(color: const Color(0xFFF1F1EE).withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            // Risk legend row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegendDot(AppTheme.errorRed, AppLocalizations.of(context)!.highRisk),
                _buildLegendDot(const Color(0xFFFCAB28), AppLocalizations.of(context)!.medium),
                _buildLegendDot(const Color(0xFFC0C9BB), AppLocalizations.of(context)!.lowRisk),
              ],
            ),
            const SizedBox(height: 16),
            // Scan density bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppLocalizations.of(context)!.scanYourCrop, style: TextStyle(color: const Color(0xFFF1F1EE).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                const Text('78%', style: TextStyle(color: Color(0xFFACF4A4), fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF717A6D).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.78,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFACF4A4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: const Color(0xFFF1F1EE).withOpacity(0.8), fontSize: 14)),
      ],
    );
  }

  Widget _buildOutbreakPopupCard(Outbreak outbreak) {
    final color = _getSeverityColor(outbreak.severity);
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2F312F).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF717A6D).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  outbreak.diseaseName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF1F1EE)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedOutbreak = null),
                  child: Icon(Icons.close, size: 20, color: const Color(0xFFF1F1EE).withOpacity(0.7)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(
                    outbreak.severity.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.location_on, size: 16, color: const Color(0xFFF1F1EE).withOpacity(0.7)),
                const SizedBox(width: 4),
                Text('${outbreak.distanceKm.toStringAsFixed(1)} km', style: TextStyle(color: const Color(0xFFF1F1EE).withOpacity(0.7), fontSize: 13)),
                const SizedBox(width: 12),
                Icon(Icons.people, size: 16, color: const Color(0xFFF1F1EE).withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context)!.cases(outbreak.caseCount), style: TextStyle(color: const Color(0xFFF1F1EE).withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateRiskControls(bool hasWeatherKey) {
    if (!hasWeatherKey) {
      return Positioned(
        bottom: 24,
        left: 16,
        right: 16,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2F312F).withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.noConnection,
                  style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color Legend Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2F312F).withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF717A6D).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 32, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.climateLegend} (${_getTranslatedWeatherLayerLabel(context, _activeWeatherLayer)})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFF1F1EE).withOpacity(0.9)),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(colors: _getLegendColors(_activeWeatherLayer)),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _getLegendLabels(_activeWeatherLayer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Weather Layer Toggle Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B).withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _weatherLayers.map((layer) {
                  final isSelected = _activeWeatherLayer == layer['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeWeatherLayer = layer['id']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3A5B7C) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getTranslatedWeatherLayerLabel(context, layer['id']!),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getLegendColors(String layerId) {
    if (layerId == 'temp_new') {
      return [Colors.blue, Colors.green, Colors.yellow, Colors.red];
    } else if (layerId == 'wind_new') {
      return [Colors.green[100]!, Colors.yellow, Colors.purple];
    } else if (layerId == 'clouds_new') {
      return [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.5), Colors.grey];
    } else {
      return [Colors.blue[50]!, Colors.blue[400]!, Colors.blue[900]!];
    }
  }

  List<Widget> _getLegendLabels(String layerId) {
    final l10n = AppLocalizations.of(context)!;
    final style = TextStyle(fontSize: 11, color: const Color(0xFFF1F1EE).withOpacity(0.7));
    if (layerId == 'temp_new') {
      return [Text('-10°C', style: style), Text('15°C', style: style), Text('30°C', style: style), Text('45°C', style: style)];
    } else if (layerId == 'wind_new') {
      return [Text('0 m/s', style: style), Text('25 m/s', style: style), Text('50 m/s', style: style)];
    } else if (layerId == 'clouds_new') {
      return [Text(l10n.clear, style: style), Text(l10n.partlyCloudy, style: style), Text(l10n.overcast, style: style)];
    } else {
      return [Text('0 mm', style: style), Text('50 mm', style: style), Text('100 mm', style: style)];
    }
  }

  String _getTranslatedWeatherLayerLabel(BuildContext context, String layerId) {
    final l10n = AppLocalizations.of(context)!;
    switch (layerId) {
      case 'clouds_new': return l10n.clouds;
      case 'temp_new': return l10n.temperature;
      case 'precipitation_new': return l10n.precipitation;
      case 'wind_new': return l10n.wind;
      default: return '';
    }
  }
}

/// Pulsing green dot for the farmer's current location.
class _PulsingLocationDot extends StatefulWidget {
  @override
  State<_PulsingLocationDot> createState() => _PulsingLocationDotState();
}

class _PulsingLocationDotState extends State<_PulsingLocationDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing ring
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 48 * _controller.value,
              height: 48 * _controller.value,
              decoration: BoxDecoration(
                color: const Color(0xFFACF4A4).withOpacity(0.3 * (1.0 - _controller.value)),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        // Inner glowing dot
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFACF4A4),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF2F312F), width: 2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFACF4A4).withOpacity(0.8), blurRadius: 10),
            ],
          ),
        ),
      ],
    );
  }
}
