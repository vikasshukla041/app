import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../l10n/app_localizations.dart';

/// Sign-in button. Disables itself and shows a spinner while logging in.
class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const LoginButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.signInButtonSemantics,
      button: true,
      // No height: the button theme sets the minimum, and it is taller than this was.
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: AppSizing.spinnerMd,
                  height: AppSizing.spinnerMd,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.signInButton),
        ),
      ),
    );
  }
}
