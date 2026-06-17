import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Semicircle gauge that visualises the farm's soil health score (0–100).
///
/// Color ranges:
///   0-30   Poor       → Red
///  31-60   Moderate   → Orange
///  61-80   Good       → Green
///  81-100  Excellent  → Dark Green
///
/// Uses TweenAnimationBuilder for smooth, automatic transitions between scores.
class SoilHealthDial extends StatelessWidget {
  final int score;

  const SoilHealthDial({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingMd,
            bottom: AppTheme.spacingSm,
          ),
          child: Text(
            'Soil Health Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score.toDouble()),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, animatedScore, _) {
              final label = _getLabel(animatedScore.round());
              final color = _scoreColor(animatedScore / 100);
              return SizedBox(
                width: 220,
                height: 140,
                child: CustomPaint(
                  painter: _DialPainter(score: animatedScore),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          animatedScore.round().toString(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _getLabel(int score) {
    if (score >= 81) return 'Excellent';
    if (score >= 61) return 'Good';
    if (score >= 31) return 'Moderate';
    return 'Poor';
  }

  static Color _scoreColor(double t) {
    if (t <= 0.30) return const Color(0xFFE53935); // Poor — Red
    if (t <= 0.60) return const Color(0xFFFB8C00); // Moderate — Orange
    if (t <= 0.80) return const Color(0xFF43A047); // Good — Green
    return const Color(0xFF1B5E20);                // Excellent — Dark Green
  }
}

class _DialPainter extends CustomPainter {
  final double score;

  _DialPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 16;
    const startAngle = math.pi; // 180°
    const sweepAngle = math.pi; // 180°

    // ── Background track ─────────────────────────────────────────────
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppTheme.dividerGray.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // ── Colored progress arc ──────────────────────────────────────────
    final fraction = (score / 100).clamp(0.0, 1.0);
    final coloredSweep = sweepAngle * fraction;

    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: const [
          Color(0xFFE53935), // Poor — Red
          Color(0xFFFB8C00), // Moderate — Orange
          Color(0xFF43A047), // Good — Green
          Color(0xFF1B5E20), // Excellent — Dark Green
        ],
        stops: const [0.0, 0.40, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      coloredSweep,
      false,
      gradientPaint,
    );

    // ── Needle indicator dot ─────────────────────────────────────────
    final needleAngle = startAngle + coloredSweep;
    final needleX = center.dx + radius * math.cos(needleAngle);
    final needleY = center.dy + radius * math.sin(needleAngle);

    // Outer glow
    canvas.drawCircle(
      Offset(needleX, needleY),
      10,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
    // Inner dot — matches current score color
    canvas.drawCircle(
      Offset(needleX, needleY),
      6,
      Paint()..color = SoilHealthDial._scoreColor(fraction),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.score != score;
}
