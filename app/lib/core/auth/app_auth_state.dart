import 'package:equatable/equatable.dart';

import 'domain/user.dart';

/// States representing app-level authentication status.
sealed class AppAuthState extends Equatable {
  const AppAuthState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Cold boot state before session check completes.
class AppAuthInitial extends AppAuthState {
  const AppAuthInitial();
}

/// User has an active authenticated session.
class AppAuthenticated extends AppAuthState {
  const AppAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

/// A saved session exists but is locked behind a biometric unlock.
///
/// Distinct from [AppUnauthenticated]: the credentials are still valid, so the
/// UI must offer an unlock — not a password form.
class AppAuthLocked extends AppAuthState {
  const AppAuthLocked(this.user);

  final User user;

  @override
  List<Object?> get props => <Object?>[user];
}

/// User is unauthenticated (logged out or session expired).
class AppUnauthenticated extends AppAuthState {
  const AppUnauthenticated();
}
