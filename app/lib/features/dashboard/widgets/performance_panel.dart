import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../performance_cubit.dart';
import '../performance_state.dart';
import 'performance_chart.dart';
import 'performance_chart_message.dart';
import 'performance_range_selector.dart';
import 'performance_summary.dart';

/// Range buttons, then the change and chart for that range, or a spinner or error in their place.
class PerformancePanel extends StatelessWidget {
  const PerformancePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return BlocBuilder<PerformanceCubit, PerformanceState>(
      builder: (BuildContext context, PerformanceState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PerformanceRangeSelector(
            selected: state.range,
            onSelected: context.read<PerformanceCubit>().load,
          ),
          const SizedBox(height: AppSpacing.md),
          // A sealed switch: adding a state without handling it here will not compile.
          switch (state) {
            PerformanceLoading() => const SizedBox(
              height: AppSizing.chartHeight,
              child: Center(child: CircularProgressIndicator()),
            ),
            PerformanceError() => PerformanceChartMessage(
              message: l10n.performanceChartLoadError,
              actionLabel: l10n.retry,
              onAction: context.read<PerformanceCubit>().load,
            ),
            PerformanceLoaded(:final history) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PerformanceSummary(history: history),
                const SizedBox(height: AppSpacing.md),
                PerformanceChart(history: history),
              ],
            ),
          },
        ],
      ),
    );
  }
}
