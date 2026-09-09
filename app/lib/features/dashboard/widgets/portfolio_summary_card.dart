import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens/app_radius.dart';
import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Card component displaying the total portfolio balance, daily returns in green,
/// and total unrealized gain.
class PortfolioSummaryCard extends StatelessWidget {
  /// Every figure is required and pre-formatted by the caller. Defaults here
  /// would be hardcoded currency strings, which render as euros with English
  /// grouping under every locale — a bug invisible until launch.
  const PortfolioSummaryCard({
    super.key,
    required this.totalBalance,
    required this.dailyReturnPercentage,
    required this.dailyReturnAmount,
    required this.totalGain,
  });

  final String totalBalance;
  final String dailyReturnPercentage;
  final String dailyReturnAmount;
  final String totalGain;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color positiveGreen = Theme.of(
      context,
    ).extension<AppSemanticColors>()!.positive;

    // No elevation or shape: cardTheme supplies both.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.portfolioTotalValueLabel,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              totalBalance,
              style: textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                // Returns badge in green
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: positiveGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.trending_up, size: AppSizing.iconXxs, color: positiveGreen),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$dailyReturnPercentage ($dailyReturnAmount)',
                        style: textTheme.labelMedium?.copyWith(
                          color: positiveGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      l10n.portfolioTotalGainLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      totalGain,
                      style: textTheme.bodyMedium?.copyWith(
                        color: positiveGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
