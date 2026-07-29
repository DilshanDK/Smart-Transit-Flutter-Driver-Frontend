// ignore_for_file: use_build_context_synchronously, await_only_futures, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../data/repositories/auth_repository.dart';
class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginInputController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginInputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleVerifyShift() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        DriverVerifyRequested(
          loginInput: _loginInputController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken != null) {
        if (!mounted) return;
        context.read<AuthBloc>().add(GoogleLoginRequested(idToken));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to retrieve Google ID Token. Check Firebase configuration.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${error.toString().replaceAll('Exception: ', '')}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFDC3545),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // 1. Sleek Night-Time / Charcoal Gradient Background matching the charging station vibe
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            const Color(0xFF0F1418), // Deep slate black
                            const Color(0xFF121212), // Pure black
                          ]
                        : [
                            const Color(0xFFECEFF1), // Premium light grey-blue
                            const Color(0xFFF9F9FE), // Surface bg
                          ],
                  ),
                ),
              ),

              // 2. Form Content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 3. Driver Shift Binding Graphic (Bus + Steering/Key)
                          _buildDriverConsoleGraphic(isDark, theme)
                              .animate()
                              .fade(duration: 800.ms)
                              .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),

                          const SizedBox(height: 24),

                          // 4. Header Titles
                          Text(
                            'Driver Console',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: isDark ? Colors.white : theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 6),

                          Text(
                            'Bind your driver ID & bus to begin your shift',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 40),

                          // 5. Input Fields
                          TextFormField(
                            controller: _loginInputController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Driver ID or Email',
                              prefixIcon: Icon(Icons.badge_outlined),
                              hintText: 'e.g. DR-TEST99 or driver@gmail.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your Driver ID or Email';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fade(delay: 400.ms)
                              .slideX(begin: -0.1, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              hintText: 'Enter your password',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fade(delay: 500.ms)
                              .slideX(begin: 0.1, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 32),

                          // 6. Action Button
                          ElevatedButton(
                            onPressed: state is AuthLoading ? null : _handleVerifyShift,
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                            child: state is AuthLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Sign In as Driver'),
                          ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 16),



                          OutlinedButton.icon(
                            onPressed: (_isGoogleLoading || state is AuthLoading) ? null : _handleGoogleSignIn,
                            icon: _isGoogleLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.g_mobiledata_rounded, size: 28),
                            label: Text(_isGoogleLoading ? 'Connecting to Google...' : 'Sign in with Google'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ).animate().fade(delay: 680.ms).slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 24),
                          
                          // Support Center Notice
                          Text(
                            'Need technical assistance or route assignments?\nContact transit headquarters dispatch center.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary.withOpacity(0.8),
                            ),
                          ).animate().fade(delay: 700.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Driver Console circular graphic with scanning/connecting vibes
  Widget _buildDriverConsoleGraphic(bool isDark, ThemeData theme) {
    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft pulse matching night-time bus charging stop
          Container(
            height: 140,
            width: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(isDark ? 0.08 : 0.06),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.15, 1.15), duration: 2.5.seconds),

          // Inner badge circle
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E262E) : const Color(0xFFECEFF1),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),

          // Interactive central icon (Steering Wheel / Key representing shift control)
          Icon(
            Icons.vpn_key_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .rotate(begin: -0.05, end: 0.05, duration: 2.seconds, curve: Curves.easeInOut),

          // Active dashboard radar dot
          Positioned(
            right: 42,
            bottom: 42,
            child: Container(
              height: 10,
              width: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent, // Blue GPS tracking light
              ),
            ).animate(onPlay: (controller) => controller.repeat())
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.4, 1.4), duration: 1.seconds, curve: Curves.bounceInOut)
                .boxShadow(begin: const BoxShadow(blurRadius: 0), end: const BoxShadow(blurRadius: 8, color: Colors.blueAccent), duration: 1.seconds),
          ),
        ],
      ),
    );
  }
}
