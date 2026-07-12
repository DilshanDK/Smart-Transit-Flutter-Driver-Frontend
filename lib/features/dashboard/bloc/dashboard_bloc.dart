import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository dashboardRepository;

  DashboardBloc({required this.dashboardRepository}) : super(const DashboardState()) {
    on<LoadProfileRequested>(_onLoadProfileRequested);
    on<ToggleShiftRequested>(_onToggleShiftRequested);
    on<ProcessBoardingTapRequested>(_onProcessBoardingTapRequested);
    on<ClearTapResultRequested>(_onClearTapResultRequested);
  }

  Future<void> _onLoadProfileRequested(LoadProfileRequested event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final profile = await dashboardRepository.getProfile();
      emit(state.copyWith(profile: profile, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  Future<void> _onToggleShiftRequested(ToggleShiftRequested event, Emitter<DashboardState> emit) async {
    final profile = state.profile;
    if (profile == null) return;

    emit(state.copyWith(isShiftToggling: true, clearError: true));
    try {
      final isOnShift = profile.isOnShift;
      final updatedProfile = isOnShift
          ? await dashboardRepository.endShift()
          : await dashboardRepository.startShift(profile);

      emit(state.copyWith(profile: updatedProfile, isShiftToggling: false));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
        isShiftToggling: false,
      ));
    }
  }

  Future<void> _onProcessBoardingTapRequested(
    ProcessBoardingTapRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isTapProcessing: true, clearTapError: true, clearTapResult: true));
    try {
      final result = await dashboardRepository.processBoardingTap(event.token, event.mode);
      emit(state.copyWith(tapResult: result, isTapProcessing: false));
    } catch (e) {
      emit(state.copyWith(
        tapError: e.toString().replaceAll('Exception: ', ''),
        isTapProcessing: false,
      ));
    }
  }

  void _onClearTapResultRequested(ClearTapResultRequested event, Emitter<DashboardState> emit) {
    emit(state.copyWith(clearTapError: true, clearTapResult: true));
  }

  @override
  Future<void> close() {
    dashboardRepository.stopTracking();
    return super.close();
  }
}
