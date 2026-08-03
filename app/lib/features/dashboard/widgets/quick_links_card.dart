import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Card component rendering a sleek List Menu for Holdings, Positions, Orders, Reports, and P&L statement.
class QuickLinksCard extends StatelessWidget {
  const QuickLinksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<Color> accents =
        Theme.of(context).extension<AppCategoryColors>()!.accents;

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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                l10n.quickLinksHeader,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(height: 1, indent: 64, endIndent: 20),
              itemBuilder: (BuildContext context, int index) {
                final _QuickMenuItem item = menuItems[index];

                return Semantics(
                  label: item.title,
                  hint: item.subtitle,
                  button: true,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    title: Text(
                      item.title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.quickLinkSelectedMessage(item.title),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
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
