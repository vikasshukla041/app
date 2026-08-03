import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/domain/user.dart';
import '../../core/design_system/widgets/app_snack_bar.dart';
import '../../l10n/app_localizations.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'widgets/biometric_opt_in_dialog.dart';
import 'widgets/brand_header.dart';
import 'widgets/login_form.dart';

/// Assembly only: reacts to state changes (biometric dialog prompt, auto biometric trigger, errors)
/// and lays out the login form.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  void _onStateChanged(BuildContext context, AuthState state) {
    switch (state) {
      case AuthInitial(:final bool autoPromptBiometrics):
        if (autoPromptBiometrics) {
          context.read<AuthCubit>().loginWithBiometrics(
                reason: AppLocalizations.of(context).biometricPromptReason,
              );
        }

      case AuthRequireBiometricPrompt(:final User user):
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => BiometricOptInDialog(
            user: user,
            onEnable: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().setupBiometricsPostLogin(user);
            },
            onSkip: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().skipBiometricsPostLogin(user);
            },
          ),
        );

      case AuthSuccess():
        break;

      case AuthFailure(:final AuthFailureReason reason):
        final String message = _failureMessage(context, reason);

        switch (_failureSeverity(reason)) {
          case AppSnackBarSeverity.warning:
            AppSnackBar.warning(context, message);

          case AppSnackBarSeverity.error:
            AppSnackBar.error(context, message);
        }

      case AuthLoading():
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

