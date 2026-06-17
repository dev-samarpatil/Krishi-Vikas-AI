import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Semicircle gauge that visualises the farm's soil health score (0–100).
///
/// Color gradient: Red (0-30) → Orange (30-50) → Yellow (50-70) → Green (70-100).
/// The needle rotates to point at the current score.
class SoilHealthDial extends StatefulWidget {
  final int score;

  const SoilHealthDial({super.key, required this.score});

  @override
  State<SoilHealthDial> createState() => _SoilHealthDialState();
}

class _SoilHealthDialState extends State<SoilHealthDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SoilHealthDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation = Tween<double>(
        begin: _scoreAnimation.value,
        end: widget.score.toDouble(),
      ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          child: AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, _) {
              final animatedScore = _scoreAnimation.value;
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
                          _getLabel(animatedScore.round()),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _scoreColor(animatedScore / 100),
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
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Moderate';
    if (score >= 30) return 'Fair';
    return 'Poor';
  }

  static Color _scoreColor(double t) {
    if (t < 0.3) return Color.lerp(AppTheme.errorRed, AppTheme.accentOrange, t / 0.3)!;
    if (t < 0.5) return Color.lerp(AppTheme.accentOrange, AppTheme.warningYellow, (t - 0.3) / 0.2)!;
    if (t < 0.7) return Color.lerp(AppTheme.warningYellow, AppTheme.primaryLight, (t - 0.5) / 0.2)!;
    return Color.lerp(AppTheme.primaryLight, AppTheme.primaryGreen, (t - 0.7) / 0.3)!;
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
    final trackPaint = Paint()
      ..color = AppTheme.dividerGray.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // ── Colored arc ──────────────────────────────────────────────────
    final fraction = (score / 100).clamp(0.0, 1.0);
    final coloredSweep = sweepAngle * fraction;

    // Create gradient shader along the arc
    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: const [
          AppTheme.errorRed,
          AppTheme.accentOrange,
          AppTheme.warningYellow,
          AppTheme.primaryLight,
          AppTheme.primaryGreen,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        transform: const GradientRotation(0),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      coloredSweep,
      false,
      gradientPaint,
    );

    // ── Needle / indicator dot ───────────────────────────────────────
    final needleAngle = startAngle + coloredSweep;
    final needleX = center.dx + radius * math.cos(needleAngle);
    final needleY = center.dy + radius * math.sin(needleAngle);

    // Outer glow
    canvas.drawCircle(
      Offset(needleX, needleY),
      10,
      Paint()..color = Colors.white.withOpacity(0.8),
    );
    // Inner dot
    canvas.drawCircle(
      Offset(needleX, needleY),
      6,
      Paint()..color = _dotColor(fraction),
    );
  }

  Color _dotColor(double t) {
    if (t < 0.3) return Color.lerp(AppTheme.errorRed, AppTheme.accentOrange, t / 0.3)!;
    if (t < 0.5) return Color.lerp(AppTheme.accentOrange, AppTheme.warningYellow, (t - 0.3) / 0.2)!;
    if (t < 0.7) return Color.lerp(AppTheme.warningYellow, AppTheme.primaryLight, (t - 0.5) / 0.2)!;
    return Color.lerp(AppTheme.primaryLight, AppTheme.primaryGreen, (t - 0.7) / 0.3)!;
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.score != score;
}
