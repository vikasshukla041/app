import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/app_badge.dart';
import '../../../core/design_system/widgets/app_tone.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/performance_range.dart';
import '../models/performance_history.dart';

/// The change for the picked range, like "+€18,420.50 (+14.8%)", and the range's high.
class PerformanceSummary extends StatelessWidget {
  const PerformanceSummary({super.key, required this.history, this.today});

  final PerformanceHistory history;

  /// Only for tests; the real app asks the clock.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat money = NumberFormat.simpleCurrency(
      locale: locale,
      name: history.currency,
    );
    final NumberFormat percent = NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: 1,
    );
    final bool isGain = history.change >= 0;
    final String sign = isGain ? '+' : '−';
    final String changeText =
        '$sign${money.format(history.change.abs())} '
        '($sign${percent.format(history.changeRatio.abs())})';
    final TextStyle? captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    // Wraps instead of clipping, since the badge and caption rarely fit on one phone line.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        AppBadge(
          label: changeText,
          tone: isGain ? AppTone.positive : AppTone.negative,
          icon: isGain ? Icons.trending_up : Icons.trending_down,
        ),
        Text(_caption(l10n, locale), style: captionStyle),
        Text(
          l10n.performanceHigh(money.format(history.high)),
          style: captionStyle,
        ),
      ],
    );
  }

  String _caption(AppLocalizations l10n, String locale) =>
      switch (history.range) {
        PerformanceRange.oneDay => _dayCaption(l10n, locale),
        PerformanceRange.oneWeek => l10n.performanceChangeCaptionOneWeek,
        PerformanceRange.oneMonth => l10n.performanceChangeCaptionOneMonth,
        PerformanceRange.oneYear => l10n.netWorthReturnCaption,
      };

  // On a weekend or holiday the last trading day is not today, so name its date.
  String _dayCaption(AppLocalizations l10n, String locale) {
    final DateTime? asOf = history.asOf;
    if (asOf == null || history.isFromDay(today ?? DateTime.now())) {
      return l10n.performanceChangeCaptionOneDay;
    }
    return l10n.performanceChangeCaptionOnDate(
      DateFormat.yMMMd(locale).format(asOf),
    );
  }
}
