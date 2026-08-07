import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class UsernameTextField extends StatelessWidget {
  const UsernameTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;

  /// Fired when the user presses the keyboard's "next"/"done" action.

  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.usernameFieldSemantics,
      textField: true,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.text,
        autocorrect: false,
        autofillHints: const <String>[AutofillHints.username],
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: l10n.usernameLabel,
          prefixIcon: const Icon(Icons.person_outline),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
