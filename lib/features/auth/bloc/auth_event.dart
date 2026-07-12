abstract class AuthEvent {
  const AuthEvent();
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class DriverVerifyRequested extends AuthEvent {
  final String driverId;
  final String busRegistration;
  const DriverVerifyRequested({required this.driverId, required this.busRegistration});
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
