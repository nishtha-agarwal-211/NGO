import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/error_utils.dart';

const String _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="24px" height="24px">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.5 24c0-1.63-.15-3.2-.43-4.75H24v9h12.75c-.55 2.92-2.2 5.4-4.67 7.06l7.28 5.64C43.6 36.63 46.5 30.9 46.5 24z"/>
  <path fill="#FBBC05" d="M10.54 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.98-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.28-5.64c-2.11 1.41-4.8 2.25-8.61 2.25-6.26 0-11.57-4.22-13.46-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';

/// Login screen — email + password authentication.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    return ErrorUtils.friendlyMessage(error);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final initiated = await authService.signInWithGoogle();
      if (!initiated && mounted) {
        setState(() {
          _errorMessage = 'Could not initiate Google Sign-In.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              Color(0xFF283593),
              Color(0xFF1565C0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / App Name
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      Text(
                        'श्री श्याम सेवा समिति',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'नर सेवा, नारायण सेवा',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXL),

                      // Login Card
                      Container(
                        width: size.width > 400 ? 400 : double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingLG),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sign in to continue',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingLG),

                              // Error Message
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    border: Border.all(
                                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 18,
                                        color: AppTheme.errorColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingMD),
                              ],

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingMD),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingLG),

                              // Login Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Sign In',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMD),

                              // Divider
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'or continue with',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingMD),

                              // Google Sign-In Button
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.textPrimary,
                                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.string(
                                        _googleLogoSvg,
                                        width: 22,
                                        height: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Sign in with Google',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMD),

                      // Browse News link (public access)
                      TextButton.icon(
                        onPressed: () => context.go('/news'),
                        icon: const Icon(
                          Icons.newspaper_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                        label: Text(
                          'Browse News & Media Coverage',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
