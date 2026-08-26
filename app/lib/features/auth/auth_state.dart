import 'package:equatable/equatable.dart';

import '../../core/auth/domain/user.dart';
import 'domain/auth_failure.dart';

// Re-exported so importing this file still brings the reason into scope.
export 'domain/auth_failure.dart';

// All possible states of the authentication flow.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => <Object?>[];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State emitted after password login succeeds, offering optional biometric setup.
class AuthRequireBiometricPrompt extends AuthState {
  const AuthRequireBiometricPrompt(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

// State when login succeeds.
class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

class AuthFailure extends AuthState {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}
