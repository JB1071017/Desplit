import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_icons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/interactive_mesh_background.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _onSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
      _onSuccess();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential != null) {
        _onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGithubSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await AuthService.instance.signInWithGitHub();
      if (credential != null) {
        _onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: InteractiveMeshBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              width: 390,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 34),
              decoration: BoxDecoration(
                color: const Color(0xFF141229).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.brandAccent.withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Mark & Brand Header
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo_icon.png',
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.memory,
                            color: AppColors.accentHover,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'de',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: 'Split',
                                style: TextStyle(
                                  color: AppColors.accentHover,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Header Title
                  Text(
                    'Sign In',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Email Input
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  // Password Input
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: 12),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                              activeColor: AppColors.brandAccent,
                              checkColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFF3E3B68),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Text(
                              'Remember me',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot?',
                          style: TextStyle(
                            color: AppColors.accentHover,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Primary Sign In Button
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandAccent,
                          AppColors.accentHover,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandAccent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Divider with "or continue with"
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFF262447),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Color(0xFF262447),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Social Auth Row
                  Row(
                    children: [
                      // Google
                      Expanded(
                        child: _buildSocialButton(
                          onTap: _isLoading ? () {} : _handleGoogleSignIn,
                          icon: const GoogleIcon(size: 17),
                          label: 'Google',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // GitHub
                      Expanded(
                        child: _buildSocialButton(
                          onTap: _isLoading ? () {} : _handleGithubSignIn,
                          icon: const GithubIcon(size: 17),
                          label: 'GitHub',
                        ),
                      ),
                    ],
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          AuthService.instance.cancelDesktopAuth();
                          setState(() {
                            _isLoading = false;
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                        label: const Text(
                          'Cancel browser sign-in',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Switch to Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _navigateToSignUp,
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            color: AppColors.accentHover,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget icon,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF131126),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF28254A),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
