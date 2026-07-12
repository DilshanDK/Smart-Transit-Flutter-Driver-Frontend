import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'driver_login_screen.dart';
import '../../dashboard/ui/driver_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const DriverDashboardScreen();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          return const DriverLoginScreen();
        }

        // Default splash/loading state
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
      },
    );
  }
}

