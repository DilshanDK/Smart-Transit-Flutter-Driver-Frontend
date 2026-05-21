// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../dashboard/ui/driver_dashboard_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driverIdController = TextEditingController();
  final _busRegController = TextEditingController();
  final _authViewModel = AuthViewModel();

  @override
  void dispose() {
    _driverIdController.dispose();
    _busRegController.dispose();
    _authViewModel.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyShift() async {
    if (_formKey.currentState!.validate()) {
      final success = await _authViewModel.verifyDriver(
        driverId: _driverIdController.text.trim(),
        busRegistration: _busRegController.text.trim().toUpperCase(),
      );

      if (mounted) {
        if (success) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const DriverDashboardScreen(),
              transitionsBuilder: (context, anim, secondaryAnimation, child) => FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_authViewModel.errorMessage ?? 'Shift verification failed.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: ListenableBuilder(
        listenable: _authViewModel,
        builder: (context, _) {
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
                            controller: _driverIdController,
                            decoration: const InputDecoration(
                              labelText: 'Driver ID / License Number',
                              prefixIcon: Icon(Icons.badge_outlined),
                              hintText: 'e.g. 6649f874c7db8241a...',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your Driver ID';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fade(delay: 400.ms)
                              .slideX(begin: -0.1, end: 0, curve: Curves.easeOut),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _busRegController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Bus Registration Number',
                              prefixIcon: Icon(Icons.airport_shuttle_outlined),
                              hintText: 'e.g. WP-NB-4852',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter the bus registration number';
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
                            onPressed: _authViewModel.isLoading ? null : _handleVerifyShift,
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                            child: _authViewModel.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Start Shift'),
                          ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),

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
