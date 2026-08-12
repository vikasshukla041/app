import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/app_auth_state.dart';
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.dashboardWelcomeLabel,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.user.fullname,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const PortfolioSummaryCard(),
                const SizedBox(height: 20),
                const QuickLinksCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LIVE BALANCE INTEGRATION — enable once GET /api/user/balance is working.
//
// DashboardCubit, DashboardState, PortfolioSummary and DashboardBody are all
// implemented and wired into service_locator already. Only this screen needs
// changing. Add these imports:
//
//   import '../../core/di/service_locator.dart';
//   import 'dashboard_cubit.dart';
//   import 'dashboard_state.dart';
//   import 'widgets/dashboard_body.dart';
//
// Then wrap the Scaffold in a provider and swap the card block:
//
//   return BlocProvider<DashboardCubit>(
//     create: (_) => getIt<DashboardCubit>()..loadBalance(),
//     child: Scaffold(
//       ...
//       body: BlocBuilder<AppAuthCubit, AppAuthState>(
//         builder: (context, authState) {
//           if (authState is! AppAuthenticated) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           return BlocBuilder<DashboardCubit, DashboardState>(
//             builder: (context, state) => switch (state) {
//               DashboardLoading() =>
//                 const Center(child: CircularProgressIndicator()),
//               DashboardLoaded(:final summary) => DashboardBody(
//                   userFullName: authState.user.fullname,
//                   summary: summary,
//                 ),
//               DashboardError() => Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: <Widget>[
//                       Text(l10n.dashboardLoadError),
//                       const SizedBox(height: 12),
//                       FilledButton(
//                         onPressed: () =>
//                             context.read<DashboardCubit>().loadBalance(),
//                         child: Text(l10n.retry),
//                       ),
//                     ],
//                   ),
//                 ),
//             },
//           );
//         },
//       ),
//     ),
//   );
// ---------------------------------------------------------------------------
