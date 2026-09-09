import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/app_auth_state.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/widgets/notification_permission_dialog.dart';
import 'widgets/portfolio_summary_card.dart';
import 'widgets/quick_links_card.dart';

/// Builds the dashboard UI with welcome, portfolio summary, and quick actions.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: <Widget>[
          Semantics(
            label: l10n.notificationBellSemantics,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: l10n.notificationBellTooltip,
              onPressed: () => NotificationPermissionDialog.show(context),
            ),
          ),
          Semantics(
            label: l10n.signOutTooltip,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.signOutTooltip,
              onPressed: () => context.read<AppAuthCubit>().logOut(),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AppAuthCubit, AppAuthState>(
        builder: (BuildContext context, AppAuthState state) {
          if (state is! AppAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.dashboardWelcomeLabel,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  state.user.fullname,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),
                const _PlaceholderSummaryCard(),
                const SizedBox(height: AppSpacing.xl),
                const QuickLinksCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Sample figures shown until the balance API contract is signed off; wiring
/// instructions live in docs/reference/03_DASHBOARD_FEATURE.md.
///
/// Formatted through NumberFormat rather than hardcoded, so the placeholder
/// exercises the same locale rules the real data will.
class _PlaceholderSummaryCard extends StatelessWidget {
  const _PlaceholderSummaryCard();

  static const double _totalBalance = 124580.50;
  static const double _dailyReturnAmount = 1845.20;
  static const double _dailyReturnPercentage = 1.48;
  static const double _totalGain = 14850.20;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    final NumberFormat currency = NumberFormat.simpleCurrency(locale: locale);
    final NumberFormat percent = NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: 2,
    );

    return PortfolioSummaryCard(
      totalBalance: currency.format(_totalBalance),
      dailyReturnPercentage: '+${percent.format(_dailyReturnPercentage / 100)}',
      dailyReturnAmount: '+${currency.format(_dailyReturnAmount)}',
      totalGain: '+${currency.format(_totalGain)}',
    );
  }
}
