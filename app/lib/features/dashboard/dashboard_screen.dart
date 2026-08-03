import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../auth/models/user.dart';

/// Placeholder landing screen after a successful login.
/// Will grow its own cubit/state/widgets in a later step.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: Center(
        child: Text(
          l10n.dashboardWelcome(user.fullName),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
