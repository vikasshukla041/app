import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

// reusable password input filed
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const PasswordTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onSubmitted,
  });

  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.passwordFieldSemantics,
      textField: true,
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: true,
        textInputAction: TextInputAction.done,
        autofillHints: const <String>[AutofillHints.password],
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: l10n.passwordLabel,
          prefixIcon: const Icon(Icons.lock_outline),
          // border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
