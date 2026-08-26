import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/domain/user.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_cubit.dart';

/// Post-login prompt offering to unlock future sessions with biometrics.
///
/// Owns its own busy flag rather than reading AuthLoading, so the panel stays
/// on screen while the OS biometric sheet is open instead of flicking back to
/// the login form.
class BiometricOptInPanel extends StatefulWidget {
  const BiometricOptInPanel({super.key, required this.user});

  final User user;

  @override
  State<BiometricOptInPanel> createState() => _BiometricOptInPanelState();
}

class _BiometricOptInPanelState extends State<BiometricOptInPanel> {
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
