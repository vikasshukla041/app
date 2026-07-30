import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Secondary sign-in action: fingerprint / Face ID.
///
/// Receives its behavior from the parent like [LoginButton] does; a null
/// [onPressed] renders it disabled (biometrics not available yet).
class BiometricsButton extends StatelessWidget {
  const BiometricsButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.useBiometricsSemantics,
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: _height,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.fingerprint),
          label: Text(l10n.useBiometrics),
        ),
      ),
    );
  }
}
