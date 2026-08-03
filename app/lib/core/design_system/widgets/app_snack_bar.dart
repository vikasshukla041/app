import 'package:flutter/material.dart';

import '../theme.dart';

enum AppSnackBarSeverity { warning, error }

abstract final class AppSnackBar {
  static void warning(BuildContext context, String message) =>
      _show(context, message, AppSnackBarSeverity.warning);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppSnackBarSeverity.error);

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

