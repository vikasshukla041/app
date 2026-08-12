import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/domain/user.dart';
import '../../l10n/app_localizations.dart';
import 'auth_cubit.dart';
import 'auth_failure_presenter.dart';
import 'auth_state.dart';
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

                  // Rendered inline rather than pushed as a dialog route: a
                  // route pushed from a state listener can be dropped mid-build,
                  // whereas the builder always reflects the current state.
                  if (state is AuthRequireBiometricPrompt) {
                    return _BiometricOptInPanel(user: state.user);
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

/// Post-login prompt offering to unlock future sessions with biometrics.
///
/// Owns its own busy flag rather than reading AuthLoading, so the panel stays
/// on screen while the OS biometric sheet is open instead of flicking back to
/// the login form.
class _BiometricOptInPanel extends StatefulWidget {
  const _BiometricOptInPanel({required this.user});

  final User user;

  @override
  State<_BiometricOptInPanel> createState() => _BiometricOptInPanelState();
}

class _BiometricOptInPanelState extends State<_BiometricOptInPanel> {
  static const double _spinnerSize = 20;

  bool _busy = false;

  Future<void> _enable() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    await context.read<AuthCubit>().setupBiometricsPostLogin(widget.user);
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  void _skip() {
    if (_busy) {
      return;
    }
    context.read<AuthCubit>().skipBiometricsPostLogin(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.fingerprint, size: 72, color: colors.primary),
        const SizedBox(height: 24),
        Text(
          l10n.biometricOptInDialogTitle,
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.biometricOptInDialogBody,
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Semantics(
          label: l10n.biometricOptInDialogEnable,
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _enable,
              child: _busy
                  ? const SizedBox(
                      width: _spinnerSize,
                      height: _spinnerSize,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.biometricOptInDialogEnable),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: l10n.biometricOptInDialogSkip,
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _busy ? null : _skip,
              child: Text(l10n.biometricOptInDialogSkip),
            ),
          ),
        ),
      ],
    );
  }
}
