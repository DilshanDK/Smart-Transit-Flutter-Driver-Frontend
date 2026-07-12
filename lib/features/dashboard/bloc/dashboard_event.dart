abstract class DashboardEvent {
  const DashboardEvent();
}

class LoadProfileRequested extends DashboardEvent {
  const LoadProfileRequested();
}

class ToggleShiftRequested extends DashboardEvent {
  const ToggleShiftRequested();
}

class ProcessBoardingTapRequested extends DashboardEvent {
  final String token;
  final String mode;
  const ProcessBoardingTapRequested({required this.token, required this.mode});
}

class ClearTapResultRequested extends DashboardEvent {
  const ClearTapResultRequested();
}
