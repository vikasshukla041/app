import 'package:flutter/material.dart';

import '../../core/design_system/widgets/coming_soon.dart';
import '../../core/navigation/app_section.dart';
import '../../l10n/app_localizations.dart';

class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      title: AppLocalizations.of(context).navHoldings,
      icon: AppSection.holdings.icon,
    );
  }
}
