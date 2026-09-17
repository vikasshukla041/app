import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/app_auth_state.dart';
import '../../core/design_system/responsive/adaptive_two_column.dart';
import '../../core/design_system/responsive/app_window_class.dart';
import '../../core/design_system/tokens/app_sizing.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/widgets/notification_permission_dialog.dart';
import 'widgets/funds_breakdown.dart';
import 'widgets/net_worth_card.dart';
import 'widgets/quick_links_card.dart';

/// Assembly only: the greeting, then the console's cards in their two groups.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

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

          // The app bar owns the top inset; this keeps the rest clear of cutouts.
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppWindowClass.of(context).pick(
                  compact: AppSpacing.xl,
                  medium: AppSpacing.xl3,
                  expanded: AppSpacing.xl3,
                ),
                vertical: AppSpacing.xl,
              ),
              // Centred and capped, or the cards stretch the full width of a monitor.
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizing.maxConsoleWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.dashboardWelcomeLabel,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        state.user.fullname,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      const _PlaceholderConsoleBody(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Sample figures, formatted the same way real data will be.
class _PlaceholderConsoleBody extends StatelessWidget {
  const _PlaceholderConsoleBody();

  // Placeholder currency, until the real balance endpoint sends one per account.
  static const String _accountCurrency = 'EUR';

  static const double _netWorth = 142850.20;
  static const double _yearReturn = 18420.50;
  static const double _availableCash = 24320.00;
  static const double _unsettled = 1850.00;
  static const double _collateral = 116680.00;

  @override
  Widget build(BuildContext context) {
    // The account is held in euros whatever the language; only the format follows it.
    final NumberFormat currency = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: _accountCurrency,
    );

    return AdaptiveTwoColumn(
      primary: <Widget>[
        NetWorthCard(
          totalValue: currency.format(_netWorth),
          yearReturn: '+${currency.format(_yearReturn)}',
        ),
      ],
      secondary: <Widget>[
        FundsBreakdown(
          availableCash: currency.format(_availableCash),
          unsettled: currency.format(_unsettled),
          collateral: currency.format(_collateral),
        ),
        const QuickLinksCard(),
      ],
    );
  }
}
