abstract class AuthEvent {
  const AuthEvent();
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Fired when the user taps "Retry" from the offline/server-unavailable screen.
class RetrySessionCheck extends AuthEvent {
  const RetrySessionCheck();
}

class DriverVerifyRequested extends AuthEvent {
  final String loginInput;
  final String password;
  const DriverVerifyRequested({required this.loginInput, required this.password});
}

class GoogleLoginRequested extends AuthEvent {
  final String idToken;
  const GoogleLoginRequested(this.idToken);
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
