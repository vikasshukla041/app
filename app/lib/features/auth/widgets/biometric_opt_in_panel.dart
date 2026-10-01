import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/domain/user.dart';
import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_cubit.dart';

/// After login prompt to unlock future session with biometrics
class BiometricOptInPanel extends StatefulWidget {
  const BiometricOptInPanel({super.key, required this.user});

  final User user;

  @override
  State<BiometricOptInPanel> createState() => _BiometricOptInPanelState();
}

class _BiometricOptInPanelState extends State<BiometricOptInPanel> {
  // static const double _spinnerSize = 20;

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
        Icon(Icons.fingerprint, size: AppSizing.iconLg, color: colors.primary),
        const SizedBox(height: AppSpacing.xl2),
        Text(
          l10n.biometricOptInDialogTitle,
          style: text.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.biometricOptInDialogBody,
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl3),
        Semantics(
          label: l10n.biometricOptInDialogEnable,
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _enable,
              child: _busy
                  ? const SizedBox(
                      width: AppSizing.spinnerSm,
                      height: AppSizing.spinnerSm,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.biometricOptInDialogEnable),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
