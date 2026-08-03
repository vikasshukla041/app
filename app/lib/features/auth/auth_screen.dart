import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design_system/widgets/app_snack_bar.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'models/user.dart';
import 'widgets/brand_header.dart';
import 'widgets/login_form.dart';

/// Assembly only: provides the cubit, reacts to navigation/error states,
/// and lays out the form. All logic lives in [AuthCubit].
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      // Availability decides what the form offers, so it is resolved as
      // soon as the screen exists.
      create: (_) => AuthCubit()..checkBiometricAvailability(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: BlocConsumer<AuthCubit, AuthState>(
                  listener: _onStateChanged,
                  builder: (BuildContext context, AuthState state) {
                    final AppLocalizations l10n = AppLocalizations.of(context);
                    final TextTheme text = Theme.of(context).textTheme;
                    final ColorScheme colors = Theme.of(context).colorScheme;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const BrandHeader(),
                        const SizedBox(height: 40),
                        Text(l10n.welcomeBack, style: text.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginSubtitle,
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const LoginForm(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    switch (state) {
      case AuthSuccess(:final User user):
        // Replace, not push: the back gesture must never return an
        // authenticated user to the login form.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => DashboardScreen(user: user),
          ),
        );
      case AuthFailure(:final AuthFailureReason reason):
        AppSnackBar.show(
          context,
          _failureMessage(context, reason),
          _failureSeverity(reason),
        );
      case AuthInitial() || AuthLoading():
        break;
    }
  }

  String _failureMessage(BuildContext context, AuthFailureReason reason) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return switch (reason) {
      AuthFailureReason.network => l10n.errorNetwork,
      AuthFailureReason.credentials => l10n.errorCredentials,
      AuthFailureReason.tooManyAttempts => l10n.errorTooManyAttempts,
      AuthFailureReason.serverUnavailable => l10n.errorServerUnavailable,
      AuthFailureReason.biometricLockedOut => l10n.errorBiometricLockedOut,
      AuthFailureReason.biometricSessionExpired =>
        l10n.errorBiometricSessionExpired,
      AuthFailureReason.generic => l10n.errorGeneric,
    };
  }

  /// Connectivity problems are recoverable by the user; account problems
  /// are not, so they carry error rather than warning colours.
  AppSnackBarSeverity _failureSeverity(AuthFailureReason reason) =>
      switch (reason) {
        AuthFailureReason.network ||
        AuthFailureReason.serverUnavailable ||
        AuthFailureReason.biometricLockedOut ||
        AuthFailureReason.biometricSessionExpired =>
          AppSnackBarSeverity.warning,
        _ => AppSnackBarSeverity.error,
      };
}
