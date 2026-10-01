import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens/app_opacity.dart';
import '../../../core/design_system/tokens/app_radius.dart';
import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// The account menu: holdings, positions, orders, reports and the P&L statement.
class QuickLinksCard extends StatelessWidget {
  const QuickLinksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<Color> accents = Theme.of(
      context,
    ).extension<AppCategoryColors>()!.accents;

    final List<_QuickMenuItem> menuItems = <_QuickMenuItem>[
      _QuickMenuItem(
        icon: Icons.pie_chart_outline,
        title: l10n.quickLinkHoldingsTitle,
        subtitle: l10n.quickLinkHoldingsSubtitle,
        color: accents[0],
      ),
      _QuickMenuItem(
        icon: Icons.show_chart,
        title: l10n.quickLinkPositionsTitle,
        subtitle: l10n.quickLinkPositionsSubtitle,
        color: accents[1],
      ),
      _QuickMenuItem(
        icon: Icons.assignment_outlined,
        title: l10n.quickLinkOrdersTitle,
        subtitle: l10n.quickLinkOrdersSubtitle,
        color: accents[2],
      ),
      _QuickMenuItem(
        icon: Icons.description_outlined,
        title: l10n.quickLinkReportsTitle,
        subtitle: l10n.quickLinkReportsSubtitle,
        color: accents[3],
      ),
      _QuickMenuItem(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.quickLinkPnlTitle,
        subtitle: l10n.quickLinkPnlSubtitle,
        color: accents[4],
      ),
    ];

    // No elevation or shape: cardTheme supplies both.
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Text(l10n.quickLinksHeader, style: textTheme.titleMedium),
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(
                    indent: AppSizing.iconMd,
                    endIndent: AppSpacing.xl,
                  ),
              itemBuilder: (BuildContext context, int index) {
                final _QuickMenuItem item = menuItems[index];

                return Semantics(
                  label: item.title,
                  hint: item.subtitle,
                  button: true,
                  // No contentPadding or text styles: listTileTheme supplies them.
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: AppOpacity.tint),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: AppSizing.iconXs,
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => AppSnackBar.success(
                      context,
                      l10n.quickLinkSelectedMessage(item.title),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMenuItem {
  const _QuickMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
