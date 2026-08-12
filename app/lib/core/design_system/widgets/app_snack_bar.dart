import 'package:flutter/material.dart';

import '../theme.dart';

/// How loudly a snackbar should speak.
///
/// [warning] is for problems the user can retry past; [error] for ones they
/// cannot; [success] confirms something worked. Material 3 defines a role for
/// error only, so the other two come from [AppSemanticColors].
enum AppSnackBarSeverity { success, warning, error }

abstract final class AppSnackBar {
  static void success(BuildContext context, String message) =>
      show(context, message, AppSnackBarSeverity.success);

  static void warning(BuildContext context, String message) =>
      show(context, message, AppSnackBarSeverity.warning);

  static void error(BuildContext context, String message) =>
      show(context, message, AppSnackBarSeverity.error);

  /// Dispatches on a severity computed elsewhere — the failure presenters map
  /// a reason to a severity and hand it straight here, so adding a case to the
  /// enum never breaks them.
  static void show(
    BuildContext context,
    String message,
    AppSnackBarSeverity severity,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final AppSemanticColors semantic = theme.extension<AppSemanticColors>()!;

    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (severity) {
      AppSnackBarSeverity.success => (
        semantic.successContainer,
        semantic.onSuccessContainer,
        Icons.check_circle_outline,
      ),
      AppSnackBarSeverity.warning => (
        semantic.warningContainer,
        semantic.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      AppSnackBarSeverity.error => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.error_outline,
      ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Row(
            children: <Widget>[
              Icon(icon, color: foreground),
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
