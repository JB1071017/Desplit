import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_icons.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/interactive_mesh_background.dart';
import 'dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  void _onSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  Future<void> _handleEmailSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter all required fields.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        username: username.isNotEmpty ? username : null,
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

  Future<void> _handleGoogleSignUp() async {
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

  Future<void> _handleGithubSignUp() async {
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
                    'Create Account',
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

                  const SizedBox(height: 22),

                  // Username Input
                  CustomTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    prefixIcon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 12),

                  // Email Input
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 12),

                  // Password Input
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),

                  const SizedBox(height: 12),

                  // Confirm Password Input
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm password',
                    prefixIcon: Icons.lock_reset_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: 22),

                  // Primary Create Account Button
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
                      onPressed: _isLoading ? null : _handleEmailSignUp,
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
                              'Create Account',
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
                          onTap: _isLoading ? () {} : _handleGoogleSignUp,
                          icon: const GoogleIcon(size: 17),
                          label: 'Google',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // GitHub
                      Expanded(
                        child: _buildSocialButton(
                          onTap: _isLoading ? () {} : _handleGithubSignUp,
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

                  // Switch to Sign In
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Text(
                          'Sign in',
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
