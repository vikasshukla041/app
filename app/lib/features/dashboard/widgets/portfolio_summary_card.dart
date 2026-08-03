import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Card component displaying the total portfolio balance, daily returns in green,
/// and total unrealized gain.
class PortfolioSummaryCard extends StatelessWidget {
  const PortfolioSummaryCard({
    super.key,
    this.totalBalance = '€124,580.50',
    this.dailyReturnPercentage = '+1.48%',
    this.dailyReturnAmount = '+€1,845.20',
    this.totalGain = '+€14,850.20',
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
    final Color positiveGreen =
        Theme.of(context).extension<AppSemanticColors>()!.positive;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.portfolioTotalValueLabel,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalBalance,
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                // Returns badge in green
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: positiveGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: positiveGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$dailyReturnPercentage ($dailyReturnAmount)',
                        style: textTheme.labelMedium?.copyWith(
                          color: positiveGreen,
                          fontWeight: FontWeight.bold,
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

