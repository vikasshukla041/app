import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../app_section.dart';

/// The side menu for tablets — shows every section.
class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.profileMenu,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;

  /// Pinned to the bottom of the menu, below every section.
  final Widget profileMenu;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    const List<AppSection> all = AppSection.values;

    return SafeArea(
      top: false,
      child: Column(
        children: <Widget>[
          Expanded(
            // A sideways phone is wide enough but too short for six labels.
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: all.indexOf(selected),
                        onDestinationSelected: (int index) =>
                            onSelected(all[index]),
                        labelType: NavigationRailLabelType.all,
                        destinations: <NavigationRailDestination>[
                          for (final AppSection section in all)
                            NavigationRailDestination(
                              icon: Icon(section.icon),
                              selectedIcon: Icon(section.selectedIcon),
                              label: Text(section.label(l10n)),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: profileMenu,
          ),
        ],
      ),
    );
  }
}
