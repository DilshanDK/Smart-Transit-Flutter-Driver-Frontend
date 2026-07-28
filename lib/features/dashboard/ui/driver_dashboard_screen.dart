// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import 'camera_scanner_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _handleStartShift(BuildContext context, bool isOnShift) {
    if (isOnShift) {
      context.read<DashboardBloc>().add(const ToggleShiftRequested());
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF161C22) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF28A745), size: 28),
              const SizedBox(width: 10),
              Text(
                'Location Consent',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Transit collects location data to enable real-time vehicle tracking for passengers, distance-based fare calculation, and shift telemetry, even when the app is closed or not in use.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This permission is required to run your driver shift. Tracking stops automatically once you end your shift.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Deny',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<DashboardBloc>().add(const ToggleShiftRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Agree & Start',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.profile == null) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0F1418) : const Color(0xFFF9F9FE),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF28A745)),
            ),
          );
        }

        final pages = [
          _buildHomeTab(state, isDark, theme),
          _buildBoardingTab(state, isDark),
          _buildProfileTab(state, isDark),
        ];

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F1418) : const Color(0xFFF9F9FE),
          body: Stack(
            children: [
              // Ambient glows (Dark Mode only)
              if (isDark) ...[
                Positioned(
                  top: -100,
                  right: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF28A745).withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              SafeArea(
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(isDark),
        );
      },
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E2E7),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF28A745),
            unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF9E9E9E),
            showSelectedLabels: true,
            showUnselectedLabels: false,
            selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Console',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_outlined),
                activeIcon: Icon(Icons.qr_code_scanner),
                label: 'Boarding',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: 400.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHomeTab(DashboardState state, bool isDark, ThemeData theme) {
    final profile = state.profile;
    final isOnShift = profile?.isOnShift ?? false;
    final greeting = _getGreeting();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  Text(
                    profile?.fullName ?? 'Driver',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF28A745).withOpacity(0.15),
                child: Text(
                  profile?.initials ?? 'D',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF28A745)),
                ),
              ),
            ],
          ).animate().fade().slideX(begin: -0.05, end: 0),

          const SizedBox(height: 28),

          // Shift Status Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E2E7),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shift Console',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOnShift ? const Color(0xFF28A745).withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOnShift ? 'ON DUTY' : 'OFF DUTY',
                        style: GoogleFonts.inter(
                          color: isOnShift ? const Color(0xFF28A745) : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('Bus Number', profile?.busRegistration ?? 'Not Bound', isDark),
                    ),
                    Expanded(
                      child: _buildInfoItem('Driver ID', profile?.driverId ?? 'N/A', isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state.isShiftToggling
                        ? null
                        : () => _handleStartShift(context, isOnShift),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnShift ? Colors.redAccent : const Color(0xFF28A745),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state.isShiftToggling
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isOnShift ? 'End Shift' : 'Start Shift',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fade().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 28),

          // Route Details Card
          if (isOnShift) ...[
            Text(
              'Active Route details',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
            ).animate().fade(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E2E7),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.route_outlined, color: Color(0xFF28A745)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route 120 - Colombo to Horana',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Next Stop: Nugegoda',
                          style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fade().slideY(begin: 0.1, end: 0),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  Widget _buildBoardingTab(DashboardState state, bool isDark) {
    final isOnShift = state.profile?.isOnShift ?? false;

    if (!isOnShift) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              Text(
                'Boarding Console Locked',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'Please start your shift from the Console tab to begin scanning passenger tickets.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger Boarding',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan tickets or tap NFC cards to collect fare',
            style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(height: 28),

          // Central Scanner Placeholder Button
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CameraScannerScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF28A745).withOpacity(0.08),
                        border: Border.all(color: const Color(0xFF28A745).withOpacity(0.3), width: 3),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_scanner, size: 72, color: Color(0xFF28A745)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tap to Scan Ticket',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(DashboardState state, bool isDark) {
    final profile = state.profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFF28A745).withOpacity(0.15),
            child: Text(
              profile?.initials ?? 'D',
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF28A745)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile?.fullName ?? 'Driver Name',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          Text(
            profile?.email ?? '',
            style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(height: 32),

          // Profile tiles
          _buildProfileTile('Licence Number', profile?.driverId ?? 'N/A', Icons.badge_outlined, isDark),
          _buildProfileTile('Bus Assignment', profile?.busRegistration ?? 'None', Icons.airport_shuttle_outlined, isDark),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Log Out', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              context.read<AuthBloc>().add(const LogoutRequested());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(String label, String value, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E2E7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
