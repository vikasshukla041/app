import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/app_auth_cubit.dart';
import '../../auth/app_auth_state.dart';
import '../../design_system/tokens/app_sizing.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../app_section.dart';

/// avatar top-right, menu that drop down from it
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.extras,
    required this.onSectionSelected,
    this.overlapAvatar = false,
  });

  /// extra navlink - which goes to profile
  final List<AppSection> extras;
  final ValueChanged<AppSection> onSectionSelected;

  /// true whn profile bottom bcoz popup open down
  final bool overlapAvatar;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppAuthState session = context.watch<AppAuthCubit>().state;
    final String name = session is AppAuthenticated
        ? session.user.fullname
        : '';

    return Semantics(
      label: l10n.profileMenuSemantics,
      button: true,
      child: PopupMenuButton<_ProfileChoice>(
        // in header popup open below and side open above
        position: overlapAvatar
            ? PopupMenuPosition.over
            : PopupMenuPosition.under,
        tooltip: l10n.profileMenuTooltip,
        onSelected: (_ProfileChoice choice) {
          switch (choice) {
            case _OpenDestination(:final AppSection section):
              onSectionSelected(section);
            case _SignOut():
              context.read<AppAuthCubit>().logOut();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<_ProfileChoice>>[
          for (final AppSection extra in extras)
            PopupMenuItem<_ProfileChoice>(
              value: _OpenDestination(extra),
              child: _MenuRow(icon: extra.icon, label: extra.label(l10n)),
            ),
          if (extras.isNotEmpty) const PopupMenuDivider(),
          PopupMenuItem<_ProfileChoice>(
            value: const _SignOut(),
            child: _MenuRow(icon: Icons.logout, label: l10n.signOutTooltip),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: CircleAvatar(
            radius: AppSizing.avatar / 2,
            child: Text(_initials(name)),
          ),
        ),
      ),
    );
  }

  /// give name single letter VS
  static String _initials(String fullname) {
    final List<String> words = fullname
        .split(' ')
        .where((String word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return '';
    }
    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }
    return (words.first[0] + words.last[0]).toUpperCase();
  }
}

/// menu: icon, gap, label
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: AppSizing.iconXs),
        const SizedBox(width: AppSpacing.md),
        Flexible(child: Text(label)),
      ],
    );
  }
}

/// what user picked from menu
sealed class _ProfileChoice {
  const _ProfileChoice();
}

class _OpenDestination extends _ProfileChoice {
  const _OpenDestination(this.section);

  final AppSection section;
}

class _SignOut extends _ProfileChoice {
  const _SignOut();
}
