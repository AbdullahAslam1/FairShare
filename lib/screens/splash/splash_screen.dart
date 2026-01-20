import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/riverpod/auth_provider.dart';
// ADDED: Import NavigationService and AppRouter
import 'package:fairshare/core/navigation/navigation_service.dart';
import 'package:fairshare/core/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo scale animation - subtle bounce
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Fade animation for text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    // Slide animation for tagline
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Navigate after animation completes
    _checkAuthStatus();
  }

  // FIXED: Updated navigation logic
  Future<void> _checkAuthStatus() async {
    // CHANGED: Reduced from 2500ms to 1800ms to match animation duration
    // This prevents conflict with auth listener in main.dart (which has 300ms delay)
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    final authState = ref.read(authProvider);

    debugPrint('🔍 Splash: Checking auth status');
    debugPrint('   - Authenticated: ${authState.isAuthenticated}');
    debugPrint('   - Email Verified: ${authState.isEmailVerified}');

    // Check if user is authenticated and email is verified
    if (authState.isAuthenticated && authState.isEmailVerified) {
      // CHANGED: Navigate to MainScreen instead of HomeScreen
      // CHANGED: Use NavigationService instead of Navigator.of(context)
      debugPrint('✅ Splash: User verified, navigating to main screen');
      if (mounted) {
        NavigationService.navigateAndRemoveUntil(AppRoutes.main);
      }
    } else {
      // User is not logged in or email not verified, go to sign in
      debugPrint('⚠️ Splash: User not verified, navigating to login');
      if (mounted) {
        NavigationService.navigateAndRemoveUntil(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles in background
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    ScaleTransition( 
                      scale: _logoScaleAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background pattern
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: CustomPaint(
                                  painter: _LogoPatternPainter(),
                                ),
                              ),
                            ),
                            // Icon
                            Center(
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppColors.primaryGradient.createShader(
                                      Rect.fromLTWH(
                                        0,
                                        0,
                                        bounds.width,
                                        bounds.height,
                                      ),
                                    ),
                                child: const Icon(
                                  Icons.pie_chart_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App name
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'FairShare',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tagline with slide animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Split expenses, share fairly',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.95),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Version text at bottom
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for subtle pattern in logo
class _LogoPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.teal600.withOpacity(0.05),
          AppColors.purple600.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Draw subtle diagonal lines
    for (int i = -1; i < 8; i++) {
      final path = Path();
      path.moveTo(i * 30.0, 0);
      path.lineTo(i * 30.0 + size.height, size.height);
      path.lineTo(i * 30.0 + size.height + 2, size.height);
      path.lineTo(i * 30.0 + 2, 0);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
