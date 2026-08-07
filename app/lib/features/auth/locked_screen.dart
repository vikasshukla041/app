import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/domain/user.dart';
import '../../l10n/app_localizations.dart';
import 'auth_cubit.dart';
import 'auth_failure_presenter.dart';
import 'auth_state.dart';
import 'widgets/brand_header.dart';

/// Shown when a valid session exists but is locked behind biometrics.
///
/// The user is still signed in, so this offers an unlock — never a password
/// form. Signing out is the way to switch accounts or recover from a device
/// whose biometrics stopped working.
class LockedScreen extends StatefulWidget {
  const LockedScreen({super.key, required this.user});

  final User user;

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> {
  static const double _maxContentWidth = 420;

  @override
  void initState() {
    super.initState();
    // Prompt immediately on arrival; the user can retry from the button if
    // they dismiss it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  void _unlock() {
    if (!mounted) {
      return;
    }
    context.read<AuthCubit>().loginWithBiometrics(
      reason: AppLocalizations.of(context).biometricPromptReason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (BuildContext context, AuthState state) {
                  if (state is AuthFailure) {
                    state.reason.show(context);
                  }
                },
                builder: (BuildContext context, AuthState state) {
                  final bool isUnlocking = state is AuthLoading;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const BrandHeader(),
                      const SizedBox(height: 48),
                      Icon(Icons.lock_outline, size: 64, color: colors.primary),
                      const SizedBox(height: 24),
                      Text(
                        l10n.dashboardWelcomeLabel,
                        style: text.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.fullname,
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Semantics(
                        label: l10n.useBiometricsSemantics,
                        button: true,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isUnlocking ? null : _unlock,
                            icon: const Icon(Icons.fingerprint),
                            label: Text(l10n.useBiometrics),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: l10n.signOutSemantics,
                        button: true,
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: isUnlocking
                                ? null
                                : () => context.read<AppAuthCubit>().logOut(),
                            child: Text(l10n.signOutAndUseAnotherAccount),
                          ),
                        ),
                      ),
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
}
