import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/app_badge.dart';
import '../../../core/design_system/widgets/app_tone.dart';
import '../../../l10n/app_localizations.dart';
import 'performance_chart_placeholder.dart';

/// Shows the account's total value, this year's return, and a performance chart.
class NetWorthCard extends StatelessWidget {
  /// No default values, since a default would hardcode one currency format.
  const NetWorthCard({
    super.key,
    required this.totalValue,
    required this.yearReturn,
  });

  final String totalValue;
  final String yearReturn;

  // Label takes 3 parts, badge takes 2 — label is wider.
  static const int _labelFlex = 3;
  static const int _badgeFlex = 2;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  flex: _labelFlex,
                  child: Text(
                    l10n.netWorthLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Badge can shrink here so it never overflows.
                Flexible(
                  flex: _badgeFlex,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppBadge(
                      label: l10n.netWorthAggregated,
                      tone: AppTone.brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Shrink the text if it does not fit — better small than cut off.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                totalValue,
                maxLines: 1,
                softWrap: false,
                style: theme.extension<AppFigureText>()!.large,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap instead of cutting off — these two rarely fit side by side on a phone.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                AppBadge(
                  label: yearReturn,
                  tone: AppTone.positive,
                  icon: Icons.trending_up,
                ),
                Text(
                  l10n.netWorthReturnCaption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const PerformanceChartPlaceholder(),
          ],
        ),
      ),
    );
  }
}
