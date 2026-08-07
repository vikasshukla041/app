import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Submit button that disables itself and shows spinner while loading preventing duplicate login req
class LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const LoginButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  static const double _height = 48;
  static const double _spinnerSize = 24;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.signInButtonSemantics,
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: _height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: _spinnerSize,
                  height: _spinnerSize,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.signInButton),
        ),
      ),
    );
  }
}
