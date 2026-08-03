import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Opt-in for saving the session behind a biometric unlock.
///
/// Shown only when the device supports biometrics and no session has been
/// saved yet, so the user consents explicitly rather than being enrolled
/// silently on their behalf.
class BiometricOptInTile extends StatelessWidget {
  const BiometricOptInTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return CheckboxListTile(
      value: value,
      onChanged: onChanged == null
          ? null
          : (bool? checked) => onChanged!(checked ?? false),
      title: Text(l10n.biometricOptIn),
      secondary: const Icon(Icons.fingerprint),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
