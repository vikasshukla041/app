import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens/app_sizing.dart';
import '../tokens/app_spacing.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: AppSizing.iconMd,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.comingSoonBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
