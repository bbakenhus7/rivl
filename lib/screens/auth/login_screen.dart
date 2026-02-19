// screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../widgets/rivl_logo.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isAppleLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await context.read<AuthProvider>().signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        FocusScope.of(context).unfocus();
        Navigator.of(context).pushReplacement(
          FadePageRoute(page: const MainScreen()),
        );
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bottom-right gradient fade decoration
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    RivlColors.primary.withOpacity(0.12),
                    RivlColors.primary.withOpacity(0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo and branding
                  SlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _buildHeader(),
                  ),
                  const SizedBox(height: 48),

                  // Login form
                  SlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _buildForm(),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    SlideIn(
                      child: _buildErrorMessage(),
                    ),

                  // Login button
                  SlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: _buildLoginButton(),
                  ),
                  const SizedBox(height: 16),

                  // Forgot password
                  SlideIn(
                    delay: const Duration(milliseconds: 350),
                    child: _buildForgotPassword(),
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  SlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: _buildDivider(),
                  ),
                  const SizedBox(height: 32),

                  // Social login buttons
                  SlideIn(
                    delay: const Duration(milliseconds: 450),
                    child: _buildSocialLogin(),
                  ),
                  const SizedBox(height: 32),

                  // Sign up link
                  SlideIn(
                    delay: const Duration(milliseconds: 500),
                    child: _buildSignUpLink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App-store-ready logo (SVG includes its own rounded background)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: RivlColors.primary.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: const RivlLogo(size: 88),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue competing',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: RivlColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: RivlColors.error,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
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
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: RivlColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: RivlColors.error,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 16),

          // Remember me checkbox
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Text(
                  'Remember me',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RivlColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RivlColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: RivlColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: RivlColors.error,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: RivlColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            SlidePageRoute(page: const ForgotPasswordScreen()),
          );
        },
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey[300]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey[300]),
        ),
      ],
    );
  }

  Widget _buildSocialLogin() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: Icons.apple,
            label: 'Apple',
            isLoading: _isAppleLoading,
            onPressed: (_isAppleLoading || _isGoogleLoading) ? () {} : () async {
              setState(() {
                _isAppleLoading = true;
                _errorMessage = null;
              });
              try {
                final success =
                    await context.read<AuthProvider>().signInWithApple();
                if (success && mounted) {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pushReplacement(
                    FadePageRoute(page: const MainScreen()),
                  );
                  return;
                }
                // Show error from provider if sign-in failed
                if (mounted) {
                  final err = context.read<AuthProvider>().errorMessage;
                  if (err != null) {
                    setState(() => _errorMessage = err);
                  }
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _errorMessage =
                        e.toString().replaceAll('Exception: ', '');
                  });
                }
              } finally {
                if (mounted) setState(() => _isAppleLoading = false);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            isLoading: _isGoogleLoading,
            onPressed: (_isAppleLoading || _isGoogleLoading) ? () {} : () async {
              setState(() {
                _isGoogleLoading = true;
                _errorMessage = null;
              });
              try {
                final success =
                    await context.read<AuthProvider>().signInWithGoogle();
                if (success && mounted) {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pushReplacement(
                    FadePageRoute(page: const MainScreen()),
                  );
                  return;
                }
                if (mounted) {
                  final err = context.read<AuthProvider>().errorMessage;
                  if (err != null) {
                    setState(() => _errorMessage = err);
                  }
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _errorMessage =
                        e.toString().replaceAll('Exception: ', '');
                  });
                }
              } finally {
                if (mounted) setState(() => _isGoogleLoading = false);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              SlidePageRoute(page: const SignUpScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
      ),
    );
  }
}
