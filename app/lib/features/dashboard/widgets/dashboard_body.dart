import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../models/portfolio_summary.dart';
import 'portfolio_summary_card.dart';
import 'quick_links_card.dart';

///Welcome header + ortfolio cards, once a balance has loaded
class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.userFullName,
    required this.summary,
  });

  final String userFullName;
  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final NumberFormat currencyFormat = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
    );
    final NumberFormat percent = NumberFormat.decimalPercentPattern(
      decimalDigits: 2,
    );
    final String sign = summary.dailyReturnAmount >= 0 ? '+' : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // User Welcome Header with Full Name
          Text(
            l10n.dashboardWelcomeLabel,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userFullName,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Portfolio Summary Card (Total Amount, Green Returns & Gain)
          PortfolioSummaryCard(
            totalBalance: currencyFormat.format(summary.netPortfolioValue),
            dailyReturnPercentage:
                '$sign${percent.format(summary.dailyReturnPercentage / 100)}',
            dailyReturnAmount:
                '$sign${currencyFormat.format(summary.dailyReturnAmount)}',
            totalGain:
                '$sign${currencyFormat.format(summary.dailyReturnAmount)}',
          ),
          const SizedBox(height: 20),

          // Quick Action Links Card (Holdings, Positions, Orders, Reports, P&L)
          const QuickLinksCard(),
        ],
      ),
    );
  }
}
