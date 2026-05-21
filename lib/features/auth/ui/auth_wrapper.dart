import 'package:flutter/material.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'driver_login_screen.dart';
import '../../dashboard/ui/driver_dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthViewModel _authViewModel = AuthViewModel();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuthenticated = await _authViewModel.checkInitialAuth();
    
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      if (isAuthenticated) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DriverDashboardScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, anim, secondaryAnimation, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DriverLoginScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder: (context, anim, secondaryAnimation, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1418) : const Color(0xFFF9F9FE),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 64, color: Color(0xFF28A745)),
            SizedBox(height: 24),
            CircularProgressIndicator(
              color: Color(0xFF28A745),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
