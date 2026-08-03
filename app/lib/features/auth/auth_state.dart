import 'package:equatable/equatable.dart';

import 'models/user.dart';

/// All possible states of the authentication flow.
///
/// `sealed` lets the compiler guarantee every state is handled.
/// Equatable gives value-equality, so emitting an identical state
/// does not trigger a redundant UI rebuild.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Resting state. Carries the device's biometric capabilities so the form
/// knows whether to offer the opt-in or enable the biometric button; the
/// Cubit returns here after a failure so those capabilities are restored.
class AuthInitial extends AuthState {
  const AuthInitial({
    this.canOfferBiometricSetup = false,
    this.canLoginWithBiometrics = false,
  });

  /// Hardware is available but no session has been saved for it yet.
  final bool canOfferBiometricSetup;

  /// Hardware is available and a saved session exists to unlock.
  final bool canLoginWithBiometrics;

  @override
  List<Object?> get props => <Object?>[
    canOfferBiometricSetup,
    canLoginWithBiometrics,
  ];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

/// Reasons a login attempt can fail, decoupled from any user-facing text
/// so the UI layer (which has a [BuildContext]) can localize the message.
enum AuthFailureReason {
  network,
  credentials,
  tooManyAttempts,
  serverUnavailable,
  biometricLockedOut,
  biometricSessionExpired,
  generic,
}

class AuthFailure extends AuthState {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}
