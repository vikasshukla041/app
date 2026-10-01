import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/app_badge.dart';
import '../../../core/design_system/widgets/app_tone.dart';
import '../../../l10n/app_localizations.dart';

/// Shows the account total and, below it, the performance panel.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({
    super.key,
    required this.totalValue,
    required this.chart,
  });

  final String totalValue;

  /// Passed in, so the card can be tested without a WebView or a Cubit.
  final Widget chart;

  /// The label gets 3 parts and the badge gets 2.
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
                // The flexible badge can shrink without overflowing.
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
            // Shrinks the text if it does not fit.
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
            const SizedBox(height: AppSpacing.lg),
            chart,
          ],
        ),
      ),
    );
  }
}
