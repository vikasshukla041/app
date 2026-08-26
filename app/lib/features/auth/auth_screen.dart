import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import 'auth_cubit.dart';
import 'auth_failure_presenter.dart';
import 'auth_state.dart';
import 'widgets/biometric_opt_in_panel.dart';
import 'widgets/brand_header.dart';
import 'widgets/login_form.dart';

/// Assembly only: reacts to state changes (auto biometric trigger, errors)
/// and lays out either the login form or the biometric opt-in panel.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const double _maxContentWidth = 420;

  @override
  void initState() {
    super.initState();
    // The cubit outlives this screen, so clear anything left over from a
    // previous session before the user tries to sign in again.
    context.read<AuthCubit>().reset();
  }

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

                  // Inline rather than a pushed dialog route: a route pushed
                  // from a listener can be dropped mid-build.
                  if (state is AuthRequireBiometricPrompt) {
                    return BiometricOptInPanel(user: state.user);
                  }

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
      // unlocking a saved session belongs to LockedScreen this screen is only
      // ever shown when there is nothing to unlock
      case AuthInitial():
        break;

      case AuthRequireBiometricPrompt():
        break;

      case AuthSuccess():
        break;

      case AuthFailure(:final AuthFailureReason reason):
        reason.show(context);

      case AuthLoading():
        break;
    }
  }
}
