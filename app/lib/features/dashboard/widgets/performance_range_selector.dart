import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/performance_range.dart';

/// The 1D / 1W / 1M / 1Y buttons above the performance chart.
class PerformanceRangeSelector extends StatelessWidget {
  const PerformanceRangeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PerformanceRange selected;
  final ValueChanged<PerformanceRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // SegmentedButton already tells a screen reader which range is selected.
    return SegmentedButton<PerformanceRange>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: <ButtonSegment<PerformanceRange>>[
        for (final PerformanceRange range in PerformanceRange.values)
          ButtonSegment<PerformanceRange>(
            value: range,
            label: Text(_shortName(l10n, range)),
            tooltip: _longName(l10n, range),
          ),
      ],
      selected: <PerformanceRange>{selected},
      onSelectionChanged: (Set<PerformanceRange> picked) =>
          onSelected(picked.first),
    );
  }

  static String _shortName(AppLocalizations l10n, PerformanceRange range) =>
      switch (range) {
        PerformanceRange.oneDay => l10n.performanceRangeOneDay,
        PerformanceRange.oneWeek => l10n.performanceRangeOneWeek,
        PerformanceRange.oneMonth => l10n.performanceRangeOneMonth,
        PerformanceRange.oneYear => l10n.performanceRangeOneYear,
      };

  static String _longName(AppLocalizations l10n, PerformanceRange range) =>
      switch (range) {
        PerformanceRange.oneDay => l10n.performanceRangeOneDayLabel,
        PerformanceRange.oneWeek => l10n.performanceRangeOneWeekLabel,
        PerformanceRange.oneMonth => l10n.performanceRangeOneMonthLabel,
        PerformanceRange.oneYear => l10n.performanceRangeOneYearLabel,
      };
}
