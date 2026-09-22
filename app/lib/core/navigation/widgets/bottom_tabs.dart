import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../app_section.dart';

/// The phone's bottom bar: one tab per entry in [AppSection.tabs].
class BottomTabs extends StatelessWidget {
  /// Shown only when a tab is open — extras have no tab to light up.
  BottomTabs({super.key, required this.selected, required this.onSelected})
    : assert(
        AppSection.tabs.contains(selected),
        'Hide the bar instead of showing it with no tab selected',
      );

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    const List<AppSection> tabs = AppSection.tabs;

    return NavigationBar(
      selectedIndex: tabs.indexOf(selected),
      onDestinationSelected: (int index) => onSelected(tabs[index]),
      destinations: <Widget>[
        for (final AppSection tab in tabs)
          NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: tab.label(l10n),
            tooltip: tab.label(l10n),
          ),
      ],
    );
  }
}
