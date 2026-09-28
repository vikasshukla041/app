import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../design_system/tokens/app_opacity.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_sizing.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/widgets/brand_header.dart';
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
    final ThemeData theme = Theme.of(context);
    const List<AppSection> all = AppSection.values;

    return SafeArea(
      top: false,
      child: SizedBox(
        width: AppSizing.sideMenuWidth,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const BrandHeader(),
                  const SizedBox(height: AppSpacing.sm),
                  // Lines up under the name, not the logo, so it reads as one block.
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSizing.logo + AppSpacing.md,
                    ),
                    child: Text(
                      selected.label(l10n).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  // Every row fills the menu, so the highlight is the same width on each.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final AppSection section in all)
                      _NavRow(
                        section: section,
                        label: section.label(l10n),
                        selected: section == selected,
                        onTap: () => onSelected(section),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: profileMenu,
            ),
          ],
        ),
      ),
    );
  }
}

/// One row: icon and label side by side, so both light up together when open.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.section,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Color foreground = selected
        ? colors.primary
        : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        // Hiding the children hides the InkWell's tap too, so it is added back.
        onTap: onTap,
        // Without this the label is announced twice — once here, once by Text.
        excludeSemantics: true,
        child: Material(
          // Unselected rows paint nothing, but still carry the hover and ripple.
          type: selected ? MaterialType.canvas : MaterialType.transparency,
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            hoverColor: colors.primary.withValues(alpha: AppOpacity.tint),
            splashColor: colors.primary.withValues(alpha: AppOpacity.tint),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected ? section.selectedIcon : section.icon,
                    color: foreground,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Wraps instead of spilling out when the text size is turned up.
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
