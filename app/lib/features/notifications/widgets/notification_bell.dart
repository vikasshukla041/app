import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'notification_permission_dialog.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.notificationBellSemantics,
      button: true,
      child: IconButton(
        icon: const Icon(Icons.notifications_none_rounded),
        tooltip: l10n.notificationBellTooltip,
        onPressed: () => NotificationPermissionDialog.show(context),
      ),
    );
  }
}
