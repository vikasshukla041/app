import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/tokens/app_sizing.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/routing/app_routes.dart';
import '../../l10n/app_localizations.dart';

/// Shows an alert opened from a push notification; a placeholder until the
/// alerts API exists.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId, this.title});

  final String alertId;

  /// Optional title from the notification payload, shown instead of a generic one.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // Opened from a notification there is no page to pop back to, so fall
        // through to the dashboard rather than leaving a dead back button.
        leading: Semantics(
          label: l10n.backSemantics,
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.backSemantics,
            // VIKAS — copy this whole onPressed.
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dashboard);
              }
            },
          ),
        ),
        title: Text(title ?? l10n.alertDetailTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.notifications_active_outlined,
                size: AppSizing.iconMd,
                color: colors.primary,
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                l10n.alertDetailHeading,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.alertDetailPlaceholder(alertId),
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
