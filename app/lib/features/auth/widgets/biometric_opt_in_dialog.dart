import 'package:flutter/material.dart';

import '../../../core/auth/domain/user.dart';
import '../../../l10n/app_localizations.dart';

/// Modal dialog shown after successful password login asking if the user
/// wants to enable Face ID / Touch ID for future launches.
class BiometricOptInDialog extends StatelessWidget {
  const BiometricOptInDialog({
    super.key,
    required this.user,
    required this.onEnable,
    required this.onSkip,
  });

  final User user;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AlertDialog(
      icon: const Icon(Icons.fingerprint, size: 48),
      title: Text(l10n.biometricOptInDialogTitle),
      content: Text(l10n.biometricOptInDialogBody),
      actions: <Widget>[
        Semantics(
          label: l10n.biometricOptInDialogSkip,
          button: true,
          child: TextButton(
            onPressed: onSkip,
            child: Text(l10n.biometricOptInDialogSkip),
          ),
        ),
        Semantics(
          label: l10n.biometricOptInDialogEnable,
          button: true,
          child: FilledButton(
            onPressed: onEnable,
            child: Text(l10n.biometricOptInDialogEnable),
          ),
        ),
      ],
    );
  }
}
