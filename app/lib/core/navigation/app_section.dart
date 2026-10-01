import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../routing/app_routes.dart';

enum AppSection {
  console(
    route: AppRoutes.dashboard,
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
  ),
  holdings(
    route: AppRoutes.holdings,
    icon: Icons.pie_chart_outline,
    selectedIcon: Icons.pie_chart,
  ),
  orders(
    route: AppRoutes.orders,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  education(
    route: AppRoutes.education,
    icon: Icons.school_outlined,
    selectedIcon: Icons.school,
  ),
  taxFiscal(
    route: AppRoutes.taxFiscal,
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
  ),
  settings(
    route: AppRoutes.settings,
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune,
  );

  const AppSection({
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final IconData icon;
  final IconData selectedIcon;

  static const List<AppSection> tabs = <AppSection>[
    console,
    holdings,
    orders,
    education,
  ];

  static const List<AppSection> extras = <AppSection>[taxFiscal, settings];

  String label(AppLocalizations l10n) {
    return switch (this) {
      AppSection.console => l10n.navConsole,
      AppSection.holdings => l10n.navHoldings,
      AppSection.orders => l10n.navOrders,
      AppSection.education => l10n.navEducation,
      AppSection.taxFiscal => l10n.navTaxFiscal,
      AppSection.settings => l10n.navSettings,
    };
  }
}
