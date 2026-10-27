import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/interactive_mesh_background.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _glowAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Fade & Scale
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 2. Subtle ambient halo breathing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entranceController.forward();

    // Auto-navigate to LoginScreen after splash presentation
    _navigationTimer = Timer(const Duration(milliseconds: 3500), _goToLogin);
  }

  void _goToLogin() {
    if (!mounted) return;

    final Widget targetScreen = AuthService.instance.currentUser != null
        ? const DashboardScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: GestureDetector(
        onTap: _goToLogin,
        child: InteractiveMeshBackground(
          child: Stack(
            children: [
              // Ambient radial glow behind the center logo
              Center(
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, _) {
                    return Container(
                      width: 480 * _glowAnimation.value,
                      height: 480 * _glowAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.brandAccent.withValues(alpha: 0.14),
                            AppColors.accentHover.withValues(alpha: 0.04),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Foreground Content
              FadeTransition(
                opacity: _fadeInAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo Icon with glowing aura
                        _buildLogoSection(),

                        const SizedBox(height: 28),

                        // Brand Name Typography
                        _buildBrandTypography(),

                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          'DECENTRALIZED GPU COMPUTE NETWORK',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            letterSpacing: 3.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom subtle version info
              Positioned(
                left: 28,
                bottom: 22,
                child: Text(
                  'deSplit Node v0.1.0 • P2P ML Engine',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandAccent.withValues(
                  alpha: 0.28 * _glowAnimation.value,
                ),
                blurRadius: 40 * _glowAnimation.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/logo_icon.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/logo_clean.png',
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => Icon(
              Icons.memory,
              size: 80,
              color: AppColors.accentHover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandTypography() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'de',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
            ),
          ),
          TextSpan(
            text: 'Split',
            style: TextStyle(
              color: AppColors.accentHover,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }
}
