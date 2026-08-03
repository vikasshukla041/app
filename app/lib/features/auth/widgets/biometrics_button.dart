import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BiometricsButton extends StatelessWidget {
  const BiometricsButton({super.key, required this.onPressed});

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

