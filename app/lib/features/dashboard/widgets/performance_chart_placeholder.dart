import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_radius.dart';
import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../l10n/app_localizations.dart';

/// Holds the curve's space at its real height until the history endpoint exists.
class PerformanceChartPlaceholder extends StatelessWidget {
  const PerformanceChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      height: AppSizing.chartHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        AppLocalizations.of(context).performanceChartPending,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
