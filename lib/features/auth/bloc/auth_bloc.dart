import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<RetrySessionCheck>(_onRetrySessionCheck);
    on<DriverVerifyRequested>(_onDriverVerifyRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onGoogleLoginRequested(GoogleLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.googleLogin(event.idToken);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _runSessionCheck(emit);
  }

  Future<void> _onRetrySessionCheck(RetrySessionCheck event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await _runSessionCheck(emit);
  }

  /// Shared session check logic used by both AppStarted and RetrySessionCheck.
  Future<void> _runSessionCheck(Emitter<AuthState> emit) async {
    try {
      final user = await authRepository.checkSession();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        // null = no token stored OR token was 401/403 and was cleared
        emit(const AuthUnauthenticated());
      }
    } on NetworkUnavailableException {
      // Backend is down / restarting — tokens are safe, DO NOT go to login
      emit(const AuthOffline());
    } catch (_) {
      // Any other unexpected error — treat same as offline to protect session
      emit(const AuthOffline());
    }
  }

  Future<void> _onDriverVerifyRequested(DriverVerifyRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.verifyDriver(event.loginInput, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
    } catch (_) {}
    emit(const AuthUnauthenticated());
  }
}
