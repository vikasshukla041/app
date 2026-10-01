import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/tokens/app_sizing.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/routing/app_routes.dart';
import '../../l10n/app_localizations.dart';

class AlertDetailsScreen extends StatelessWidget {
  const AlertDetailsScreen({super.key, required this.alertId, this.title});

  final String alertId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: l10n.backSemantics,
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.backSemantics,
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
                Icons.notifications_outlined,
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
