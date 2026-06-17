import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/supabase_client.dart';

/// Splash screen — checks JWT in Hive → routes to Home or Onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final settingsBox = Hive.box(AppConstants.settingsBox);
    final hasHiveToken = settingsBox.containsKey(AppConstants.jwtTokenKey);
    final hasCompletedOnboarding = settingsBox.get('has_completed_onboarding', defaultValue: false);
    final hasSupabaseSession = SupabaseClientService.instance.client.auth.currentSession != null;

    if (hasSupabaseSession || hasHiveToken || hasCompletedOnboarding) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutCubic,
                  )),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App icon logo
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
                      const SizedBox(height: AppTheme.spacingXl),
                      Text(
                        'KRISHI VIKAS AI',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.01,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Empowering Farmers',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              color: const Color(0xFFF9A825),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '|',
                              style: TextStyle(
                                fontSize: 18,
                                color: const Color(0xFFF9A825).withOpacity(0.6),
                              ),
                            ),
                          ),
                          Text(
                            'शेतकऱ्यांचे सक्षमीकरण',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              color: const Color(0xFFF9A825),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Wheat Silhouette at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.33,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomPaint(
                  painter: WheatSilhouettePainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WheatSilhouettePainter extends CustomPainter {
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
