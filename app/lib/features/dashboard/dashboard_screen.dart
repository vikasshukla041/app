import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/app_auth_state.dart';
import '../../core/design_system/responsive/adaptive_two_column.dart';
import '../../core/design_system/responsive/screen_size.dart';
import '../../core/design_system/tokens/app_sizing.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/di/service_locator.dart';
import 'performance_cubit.dart';
import 'widgets/funds_breakdown.dart';
import 'widgets/net_worth_card.dart';
import 'widgets/performance_panel.dart';
import 'widgets/quick_links_card.dart';

/// The console body — just the cards. The app frame owns the title row.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PerformanceCubit>(
      create: (_) => getIt<PerformanceCubit>()..load(),
      child: BlocBuilder<AppAuthCubit, AppAuthState>(
        builder: (BuildContext context, AppAuthState state) {
          if (state is! AppAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenSize.of(context).pageGap,
              vertical: AppSpacing.xl,
            ),
            // Centered with a max width, so cards do not stretch on a big screen.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizing.maxConsoleWidth,
                ),
                child: const _PlaceholderConsoleBody(),
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

  // Placeholder currency until the real balance API sends one.
  static const String _accountCurrency = 'EUR';

  static const double _netWorth = 142850.20;
  static const double _availableCash = 24320.00;
  static const double _unsettled = 1850.00;
  static const double _collateral = 116680.00;

  @override
  Widget build(BuildContext context) {
    // Account is always in euros — only the number format changes with language.
    final NumberFormat currency = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: _accountCurrency,
    );

    return AdaptiveTwoColumn(
      primary: <Widget>[
        NetWorthCard(
          totalValue: currency.format(_netWorth),
          chart: const PerformancePanel(),
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
