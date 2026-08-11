abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Backend was unreachable during session check — tokens are preserved.
/// The user should see a 'retry' UI, NOT the login screen.
class AuthOffline extends AuthState {
  const AuthOffline();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
