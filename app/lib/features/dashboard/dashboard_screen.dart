import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/app_auth_state.dart';
import '../../core/di/service_locator.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_cubit.dart';
import 'dashboard_state.dart';
import 'widgets/dashboard_body.dart';

/// Screen layout assembling user welcome header, portfolio summary, and action links.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return BlocProvider<DashboardCubit>(
      create: (_) => getIt<DashboardCubit>()..loadBalance(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dashboardTitle),
          actions: <Widget>[
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
          builder: (BuildContext context, AppAuthState authState) {
            if (authState is! AppAuthenticated) {
              return const Center(child: CircularProgressIndicator());
            }

            return BlocBuilder<DashboardCubit, DashboardState>(
              builder: (BuildContext context, DashboardState state) {
                return switch (state) {
                  DashboardLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  DashboardLoaded(:final summary) => DashboardBody(
                      userFullName: authState.user.fullname,
                      summary: summary,
                    ),
                  DashboardError() => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(l10n.dashboardLoadError),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                context.read<DashboardCubit>().loadBalance(),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                };
              },
            );
          },
        ),
      ),
    );
  }
}

