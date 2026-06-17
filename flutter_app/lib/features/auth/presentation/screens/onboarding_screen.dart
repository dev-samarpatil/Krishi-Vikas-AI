import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_vikas_ai/l10n/app_localizations.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Onboarding screen — Stitch-matched landing page with dark green gradient,
/// logo, tagline, wheat silhouette, and action buttons.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF0C3B10),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main content — centered
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // Logo
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1B5E20).withOpacity(0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuBinejyEdUXlxQ_jedeUNh6EChe2KHaMu2izyYnupFsfz_oQMXvVUXv_caFmB_ltMU7D_KBls7RGjtmz-UIcsYsBFqYufS0Rdxo_VIFBagL2FlkCFxQTq02cOMVLXbWWFnMVVShtwsNf05F-bq-0cUVCchdR-eqbez9O2rhn10GdfAT4Pfj8vF1hGAqlzNH7LxHMwH8vNuJCvyZuWPFyu7qTNyS2A9jif49npC-_6GJ9ikMdM7aRQieUyFcVvifgcNixJDa2G0dtpE',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.eco,
                                  size: 64,
                                  color: AppTheme.primaryGreen,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'KRISHI VIKAS AI',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tagline
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Empowering Farmers',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFF9A825),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '|',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFFF9A825).withOpacity(0.6),
                                ),
                              ),
                            ),
                            const Text(
                              'शेतकऱ्यांचे सक्षमीकरण',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFF9A825),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          l10n.appTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Get Started button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => context.go(AppRoutes.phoneAuth),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF9A825),
                              foregroundColor: const Color(0xFF1B5E20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFFF9A825).withOpacity(0.4),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            child: Text(l10n.getStarted),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Guest mode
                        TextButton(
                          onPressed: () => context.go(AppRoutes.farmSetup),
                          child: Text(
                            l10n.continueWithoutAccount,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Wheat Silhouette at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.25,
              child: IgnorePointer(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomPaint(
                    painter: _WheatSilhouettePainter(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheatSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0C3B10).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    final sx = size.width / 1000;
    final sy = size.height / 200;

    path.moveTo(0, 200 * sy);
    path.lineTo(0, 150 * sy);
    path.cubicTo(50 * sx, 150 * sy, 70 * sx, 120 * sy, 100 * sx, 160 * sy);
    path.cubicTo(130 * sx, 200 * sy, 160 * sx, 130 * sy, 200 * sx, 170 * sy);
    path.cubicTo(240 * sx, 210 * sy, 270 * sx, 140 * sy, 300 * sx, 180 * sy);
    path.cubicTo(330 * sx, 220 * sy, 370 * sx, 150 * sy, 400 * sx, 190 * sy);
    path.cubicTo(430 * sx, 230 * sy, 470 * sx, 160 * sy, 500 * sx, 200 * sy);
    path.cubicTo(530 * sx, 240 * sy, 570 * sx, 170 * sy, 600 * sx, 210 * sy);
    path.cubicTo(630 * sx, 250 * sy, 670 * sx, 180 * sy, 700 * sx, 220 * sy);
    path.cubicTo(730 * sx, 260 * sy, 770 * sx, 190 * sy, 800 * sx, 230 * sy);
    path.cubicTo(830 * sx, 270 * sy, 870 * sx, 200 * sy, 900 * sx, 240 * sy);
    path.cubicTo(930 * sx, 280 * sy, 970 * sx, 210 * sy, 1000 * sx, 250 * sy);
    path.lineTo(1000 * sx, 200 * sy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
