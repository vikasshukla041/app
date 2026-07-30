import 'package:equatable/equatable.dart';

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

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

/// Reasons a login attempt can fail, decoupled from any user-facing text
/// so the UI layer (which has a [BuildContext]) can localize the message.
enum AuthFailureReason {
  network,
  credentials,
  tooManyAttempts,
  serverUnavailable,
  generic,
}

class AuthFailure extends AuthState {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}
