import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../design_system/tokens/app_opacity.dart';
import '../../design_system/tokens/app_radius.dart';
import '../../design_system/tokens/app_sizing.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/widgets/brand_header.dart';
import '../app_section.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.profileMenu,
  });

  final AppSection selected;
  final ValueChanged<AppSection> onSelected;
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

                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSizing.logo + AppSpacing.md,
                    ),
                    // The selected row already says where you are, so this is not read out.
                    child: ExcludeSemantics(
                      child: Text(
                        selected.label(l10n).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1,
                        ),
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

/// icon + label on sidebar
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
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
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
