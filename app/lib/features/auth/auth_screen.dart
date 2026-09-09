import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/design_system/tokens/app_sizing.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'auth_cubit.dart';
import 'auth_failure_presenter.dart';
import 'auth_state.dart';
import 'widgets/brand_header.dart';
import 'widgets/login_form.dart';

/// Assembly only: lays out the login form and surfaces failures.
///
/// Where a successful login goes is the router's decision, not this screen's.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

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
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizing.maxContentWidth),
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
                      const SizedBox(height: AppSpacing.xl4),
                      Text(l10n.welcomeBack, style: text.headlineMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.loginSubtitle,
                        style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl3),
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
      // Unlocking a saved session is LockedScreen's job; this screen only
      // ever appears when there is nothing to unlock.
      case AuthInitial():
        break;

      // The router redirects this state to its own screen.
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
