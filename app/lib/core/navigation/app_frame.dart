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

/// Wraps every signed-in screen with a title row and navigation.
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.shell, required this.actions});

  /// The router's handle on each branch. Its index matches an [AppSection].
  final StatefulNavigationShell shell;

  /// Extra header buttons a feature wants shown, such as the bell.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool sidebar = ScreenSize.of(context).hasSidebar;
    final AppSection current = AppSection.values[shell.currentIndex];
    final AppAuthState session = context.watch<AppAuthCubit>().state;

    // On a phone, extras open as a sub-page with a back button.
    final bool onSubPage = !sidebar && AppSection.extras.contains(current);

    void open(AppSection section) {
      // Tapping the tab you are already on takes you back to its first page.
      shell.goBranch(section.index, initialLocation: section == current);
    }

    // Android back button must act like the arrow, or it exits the app.
    final Widget phoneBody = onSubPage
        ? BackButtonListener(
            onBackButtonPressed: () async {
              // Let the router close an open menu, dialog, or deeper page first.
              if (context.canPop()) return false;
              open(AppSection.console);
              return true;
            },
            child: shell,
          )
        : shell;

    // Side menu already shows extras, so only phones need them here.
    final Widget profileMenu = ProfileMenu(
      extras: sidebar ? const <AppSection>[] : AppSection.extras,
      onSectionSelected: open,
    );

    final Widget header = PageHeader(
      title: _title(current, session, l10n),
      leading: onSubPage
          ? _BackToConsole(onPressed: () => open(AppSection.console))
          : null,
      // On a sidebar layout the profile sits at the bottom of the side menu.
      actions: <Widget>[...actions, if (!sidebar) profileMenu],
    );

    return Scaffold(
      // No app bar, so the frame clears the status bar and notch itself.
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
                      children: <Widget>[header, Expanded(child: shell)],
                    ),
                  ),
                ],
              )
            : Column(
                children: <Widget>[header, Expanded(child: phoneBody)],
              ),
      ),
      bottomNavigationBar: sidebar || onSubPage
          ? null
          : BottomTabs(selected: current, onSelected: open),
    );
  }

  /// The console greets the user by name; every other section uses its label.
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
