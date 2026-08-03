import 'package:equatable/equatable.dart';

import '../../core/auth/domain/user.dart';

// All possible states of the authentication flow.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => <Object?>[];
}

class AuthInitial extends AuthState {
  const AuthInitial({
    this.canLoginWithBiometrics = false,
    this.autoPromptBiometrics = false,
  });

  /// Enables the "Use biometrics" button for a manual tap.
  final bool canLoginWithBiometrics;

  /// True only right after launch, so the OS prompt can't re-fire on cancel.
  final bool autoPromptBiometrics;

  @override
  List<Object?> get props => <Object?>[
        canLoginWithBiometrics,
        autoPromptBiometrics,
      ];
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

enum AuthFailureReason {
  network,
  credentials,
  tooManyAttempts,
  serverUnavailable,
  biometricSessionExpired,
  biometricLockedOut,
  generic,
}

class AuthFailure extends AuthState {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}

