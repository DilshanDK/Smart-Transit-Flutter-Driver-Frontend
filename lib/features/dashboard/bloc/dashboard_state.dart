import '../../../core/models/driver_models.dart';

class DashboardState {
  final DriverProfile? profile;
  final bool isLoading;
  final bool isShiftToggling;
  final bool isTapProcessing;
  final String? error;
  final String? tapError;
  final Map<String, dynamic>? tapResult;

  const DashboardState({
    this.profile,
    this.isLoading = false,
    this.isShiftToggling = false,
    this.isTapProcessing = false,
    this.error,
    this.tapError,
    this.tapResult,
  });

  DashboardState copyWith({
    DriverProfile? profile,
    bool? isLoading,
    bool? isShiftToggling,
    bool? isTapProcessing,
    String? error,
    String? tapError,
    Map<String, dynamic>? tapResult,
    bool clearError = false,
    bool clearTapError = false,
    bool clearTapResult = false,
  }) {
    return DashboardState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isShiftToggling: isShiftToggling ?? this.isShiftToggling,
      isTapProcessing: isTapProcessing ?? this.isTapProcessing,
      error: clearError ? null : (error ?? this.error),
      tapError: clearTapError ? null : (tapError ?? this.tapError),
      tapResult: clearTapResult ? null : (tapResult ?? this.tapResult),
    );
  }
}
