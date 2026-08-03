import 'package:flutter/material.dart';

import '../theme.dart';

/// How serious a message is, which decides its colour token pair.
enum AppSnackBarSeverity {
  /// The user can act on it: no connection, server unreachable.
  warning,

  /// Something is wrong with the request or account: bad credentials.
  error,
}

/// App-wide snackbar presentation.
///
/// Lives in the design system so screens stay layout-only and every
/// message looks identical. Takes a ready-made string: features own
/// their own localization.
abstract final class AppSnackBar {
  static void warning(BuildContext context, String message) =>
      _show(context, message, AppSnackBarSeverity.warning);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppSnackBarSeverity.error);

  static void show(
    BuildContext context,
    String message,
    AppSnackBarSeverity severity,
  ) => _show(context, message, severity);

  static void _show(
    BuildContext context,
    String message,
    AppSnackBarSeverity severity,
  ) {
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic = theme.extension<AppSemanticColors>()!;
    final bool isWarning = severity == AppSnackBarSeverity.warning;

    final Color background = isWarning
        ? semantic.warningContainer
        : theme.colorScheme.errorContainer;
    final Color foreground = isWarning
        ? semantic.onWarningContainer
        : theme.colorScheme.onErrorContainer;

    ScaffoldMessenger.of(context)
      // Replace any visible message: the newest result is the relevant one.
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Row(
            children: <Widget>[
              Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
                color: foreground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
