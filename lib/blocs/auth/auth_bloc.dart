import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../repositories/auth_repository.dart';

// ─── EVENTS ──────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  @override List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email, password;
  AuthSignInRequested({required this.email, required this.password});
  @override List<Object?> get props => [email];
}

class AuthRegisterRequested extends AuthEvent {
  final String email, password, displayName;
  AuthRegisterRequested({required this.email, required this.password, required this.displayName});
  @override List<Object?> get props => [email];
}

class AuthGoogleSignInRequested extends AuthEvent {}
class AuthAppleSignInRequested extends AuthEvent {}
class AuthGuestSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  AuthPasswordResetRequested({required this.email});
  @override List<Object?> get props => [email];
}

// ─── STATES ──────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  AuthAuthenticated({required this.user});
  @override List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure({required this.message});
  @override List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}

// ─── BLOC ─────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  late final StreamSubscription<User?> _authSubscription;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthAppleSignInRequested>(_onAppleSignIn);
    on<AuthGuestSignInRequested>(_onGuestSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);

    _authSubscription = authRepository.authStateChanges.listen((user) {
      if (user == null) add(AuthStarted());
    });
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignIn(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmail(
        email: event.email, password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapAuthError(e.code)));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.registerWithEmail(
        email: event.email, password: event.password, displayName: event.displayName,
      );
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapAuthError(e.code)));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onGoogleSignIn(AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapAuthError(e.code)));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled') || msg.contains('cancel')) {
        emit(AuthUnauthenticated()); // user cancelled — not an error
      } else if (msg.contains('sign_in_failed') || msg.contains('ApiException')) {
        emit(AuthFailure(message:
          'Google sign-in failed. Ensure your SHA-1 fingerprint is registered in Firebase Console.'));
      } else {
        emit(AuthFailure(message: 'Google sign-in failed. Please try again.'));
      }
    }
  }

  Future<void> _onAppleSignIn(AuthAppleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithApple();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(message: 'Apple sign-in failed. Please try again.'));
    }
  }

  Future<void> _onGuestSignIn(AuthGuestSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInAnonymously();
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        emit(AuthFailure(message: 'Guest sign-in is not enabled. Enable Anonymous auth in Firebase Console.'));
      } else {
        emit(AuthFailure(message: _mapAuthError(e.code)));
      }
    } catch (e) {
      emit(AuthFailure(message: 'Guest sign-in failed. Please try again.'));
    }
  }

  Future<void> _onSignOut(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await authRepository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onPasswordReset(AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(event.email);
      emit(AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapAuthError(e.code)));
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':        return 'No account found with this email.';
      // firebase_auth 5.x uses invalid-credential instead of wrong-password
      case 'wrong-password':
      case 'invalid-credential':    return 'Incorrect email or password.';
      case 'email-already-in-use':  return 'An account already exists with this email.';
      case 'weak-password':         return 'Password must be at least 6 characters.';
      case 'invalid-email':         return 'Please enter a valid email address.';
      case 'too-many-requests':     return 'Too many attempts. Please try again later.';
      case 'network-request-failed':return 'Check your internet connection.';
      case 'user-disabled':         return 'This account has been disabled.';
      case 'operation-not-allowed': return 'This sign-in method is not enabled.';
      case 'requires-recent-login': return 'Please sign in again to continue.';
      default: return 'Authentication failed. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
