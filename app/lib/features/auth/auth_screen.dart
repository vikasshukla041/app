import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design_system/theme.dart';
import '../../l10n/app_localizations.dart';
import '../dashboard/dashboard_screen.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
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
      create: (_) => AuthCubit(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: BlocConsumer<AuthCubit, AuthState>(
                  listener: (BuildContext context, AuthState state) {
                    if (state is AuthSuccess) {
                      // Replace, not push: the back gesture must never
                      // return an authenticated user to the login form.
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const DashboardScreen(),
                        ),
                      );
                    } else if (state is AuthFailure) {
                      _showFailureSnackBar(context, state.reason);
                    }
                  },
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

  /// Shows a severity-styled snackbar using Material 3 color tokens:
  /// user-fixable problems (network, server down) get warning colors,
  /// account problems (bad credentials, lockout) get error colors.
  void _showFailureSnackBar(BuildContext context, AuthFailureReason reason) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppSemanticColors semantic =
        Theme.of(context).extension<AppSemanticColors>()!;

    final bool isWarning = switch (reason) {
      AuthFailureReason.network || AuthFailureReason.serverUnavailable => true,
      _ => false,
    };

    final Color background =
        isWarning ? semantic.warningContainer : colors.errorContainer;
    final Color foreground =
        isWarning ? semantic.onWarningContainer : colors.onErrorContainer;

    final String message = switch (reason) {
      AuthFailureReason.network => l10n.errorNetwork,
      AuthFailureReason.credentials => l10n.errorCredentials,
      AuthFailureReason.tooManyAttempts => l10n.errorTooManyAttempts,
      AuthFailureReason.serverUnavailable => l10n.errorServerUnavailable,
      AuthFailureReason.generic => l10n.errorGeneric,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: background,
        content: Row(
          children: <Widget>[
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
