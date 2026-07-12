// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    final state = context.read<DashboardBloc>().state;
    if (state.isTapProcessing) return;

    context.read<DashboardBloc>().add(
          ProcessBoardingTapRequested(token: code, mode: 'QR'),
        );
  }

  void _resetScanner() {
    context.read<DashboardBloc>().add(const ClearTapResultRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final hasResult = state.tapResult != null || state.tapError != null;

        return Scaffold(
          backgroundColor: const Color(0xFF0F1418),
          appBar: AppBar(
            title: Text(
              'Console Scanner',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                _resetScanner();
                Navigator.pop(context);
              },
            ),
          ),
          body: Stack(
            children: [
              if (!hasResult) ...[
                // Live Scanner view
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),

                // Scanner Overlay Frame
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF28A745), width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),

                // Scanning Status / Instruction Text
                Positioned(
                  bottom: 80,
                  left: 24,
                  right: 24,
                  child: Text(
                    state.isTapProcessing ? 'Processing ticket...' : 'Align passenger QR ticket within the frame',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // Loading Indicator during active API processing
              if (state.isTapProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF28A745)),
                  ),
                ),

              // Scan Result Overlay Screen
              if (hasResult) _buildResultView(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultView(DashboardState state) {
    final isError = state.tapError != null || (state.tapResult != null && state.tapResult!['error'] == true);
    final isInsufficient = state.tapResult != null && state.tapResult!['statusCode'] == 402;
    final String event = state.tapResult?['event'] ?? '';
    final String message = state.tapError ?? state.tapResult?['message'] ?? 'Scan processed';
    final double? fare = state.tapResult?['fare'] != null ? double.tryParse(state.tapResult!['fare'].toString()) : null;

    Color themeColor = const Color(0xFF28A745);
    IconData icon = Icons.check_circle_outline_rounded;
    String statusTitle = 'BOARDING PASSED';
    String detailsText = 'Passenger successfully checked in.';

    if (isError) {
      themeColor = Colors.redAccent;
      icon = Icons.cancel_outlined;
      statusTitle = isInsufficient ? 'INSUFFICIENT FUNDS' : 'TICKET DENIED';
      detailsText = isInsufficient ? 'Passenger balance is too low for the fare.' : message;
    } else if (event == 'TAP_OFF') {
      statusTitle = 'TAP OFF COMPLETE';
      detailsText = 'Fare: LKR ${(fare ?? 0).toStringAsFixed(2)}\nJourney Completed successfully.';
    } else if (event == 'OFFLINE_SAVED') {
      themeColor = const Color(0xFFF1C40F);
      icon = Icons.offline_bolt_outlined;
      statusTitle = 'OFFLINE SAVED';
      detailsText = 'Ticket registered offline. Local cache stored. Syncing will resume automatically when internet access returns.';
    }

    return Container(
      color: const Color(0xFF0F1418),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Icon with scale animation
          Icon(icon, size: 96, color: themeColor)
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 32),

          // Status Title
          Text(
            statusTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeColor,
              letterSpacing: 1.2,
            ),
          ).animate().fade(delay: 200.ms),

          const SizedBox(height: 12),

          // Details text
          Text(
            detailsText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
              height: 1.4,
            ),
          ).animate().fade(delay: 300.ms),

          const Spacer(),

          // Next Scan Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _resetScanner,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Scan Next Ticket',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ).animate().slideY(begin: 0.2, end: 0, delay: 400.ms).fade(delay: 400.ms),
        ],
      ),
    );
  }
}
