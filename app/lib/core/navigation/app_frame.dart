import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../auth/app_auth_cubit.dart';
import '../auth/app_auth_state.dart';
import '../design_system/responsive/screen_size.dart';
import '../design_system/widgets/page_header.dart';
import 'app_section.dart';
import 'widgets/bottom_tabs.dart';
import 'widgets/profile_menu.dart';
import 'widgets/side_menu.dart';

/// after signin screen with title row and navigation
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.shell, required this.actions});

  /// go_router handle on branches. index AppSection
  final StatefulNavigationShell shell;

  /// app bar button
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool sidebar = ScreenSize.of(context).hasSidebar;
    final AppSection current = AppSection.values[shell.currentIndex];
    final AppAuthState session = context.watch<AppAuthCubit>().state;

    /// phone extra opens
    final bool onSubPage = !sidebar && AppSection.extras.contains(current);

    void open(AppSection section) {
      // tapping same tab back to first page
      shell.goBranch(section.index, initialLocation: section == current);
    }

    final Widget page = Semantics(container: true, child: shell);

    // back button
    final Widget phoneBody = onSubPage
        ? BackButtonListener(
            onBackButtonPressed: () async {
              // let router close open menu, dialog or deeper page first
              if (context.canPop()) return false;
              open(AppSection.console);
              return true;
            },
            child: page,
          )
        : page;

    final Widget profileMenu = ProfileMenu(
      extras: sidebar ? const <AppSection>[] : AppSection.extras,
      onSectionSelected: open,
      overlapAvatar: sidebar,
    );

    final Widget header = PageHeader(
      title: _title(current, session, l10n),
      leading: onSubPage
          ? _BackToConsole(onPressed: () => open(AppSection.console))
          : null,
      // on sidebar layouty, profile on left bottom
      actions: <Widget>[...actions, if (!sidebar) profileMenu],
    );

    return Scaffold(
      body: SafeArea(
        child: sidebar
            ? Row(
                children: <Widget>[
                  SideMenu(
                    selected: current,
                    onSelected: open,
                    profileMenu: profileMenu,
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        header,
                        Expanded(child: page),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: <Widget>[
                  header,
                  Expanded(child: phoneBody),
                ],
              ),
      ),
      bottomNavigationBar: sidebar || onSubPage
          ? null
          : BottomTabs(selected: current, onSelected: open),
    );
  }

  /// console greeting user by name
  String _title(
    AppSection current,
    AppAuthState session,
    AppLocalizations l10n,
  ) {
    if (current == AppSection.console && session is AppAuthenticated) {
      return l10n.dashboardWelcome(session.user.fullname);
    }
    return current.label(l10n);
  }
}

class _BackToConsole extends StatelessWidget {
  const _BackToConsole({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Semantics(
      label: l10n.backSemantics,
      button: true,
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.backSemantics,
        onPressed: onPressed,
      ),
    );
  }
}
