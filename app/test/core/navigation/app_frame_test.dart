import 'dart:async';

import 'package:activotrade_app/core/auth/app_auth_cubit.dart';
import 'package:activotrade_app/core/auth/app_auth_state.dart';
import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/core/design_system/widgets/brand_header.dart';
import 'package:activotrade_app/core/design_system/widgets/page_header.dart';
import 'package:activotrade_app/core/navigation/app_frame.dart';
import 'package:activotrade_app/core/navigation/app_section.dart';
import 'package:activotrade_app/core/navigation/widgets/side_menu.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Starts signed in, so the avatar has a name for its initials.
class _SignedInAuthCubit extends AppAuthCubit {
  _SignedInAuthCubit(SecureStorageService storage)
    : super(storageService: storage) {
    emit(
      const AppAuthenticated(
        User(id: '1', username: 'alex', fullname: 'Alex Romero'),
      ),
    );
  }

  bool signedOut = false;

  @override
  Future<void> logOut() async {
    signedOut = true;
  }
}

/// One width on each side of each breakpoint.
const double _phone = 390;
const double _smallTablet = 800;
const double _largeTablet = 1100;

void main() {
  late _SignedInAuthCubit authCubit;
  late GoRouter router;

  setUp(() {
    authCubit = _SignedInAuthCubit(MockSecureStorageService());
    router = GoRouter(
      initialLocation: AppSection.console.route,
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell shell,
              ) => AppFrame(shell: shell, actions: const <Widget>[]),
          branches: <StatefulShellBranch>[
            for (final AppSection section in AppSection.values)
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: section.route,
                    // Keyed by section, so a test can tell screens apart.
                    builder: (BuildContext context, GoRouterState state) =>
                        Text(section.name, key: Key(section.name)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await authCubit.close();
  });

  Future<void> pumpFrame(
    WidgetTester tester,
    double width, {
    double height = 900,
    double textScale = 1,
    EdgeInsets insets = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<AppAuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(
          theme: ActivoTradeTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              padding: insets,
              viewPadding: insets,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder screen(AppSection section) => find.byKey(Key(section.name));

  Future<void> openProfileMenu(WidgetTester tester) async {
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
  }

  Finder sideMenuRow(String label) =>
      find.descendant(of: find.byType(SideMenu), matching: find.text(label));

  group('which navigation shows', () {
    testWidgets('a phone gets the bottom bar', (WidgetTester tester) async {
      await pumpFrame(tester, _phone);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(SideMenu), findsNothing);
    });

    testWidgets('a small tablet already gets the side menu', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);

      expect(find.byType(SideMenu), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      // The menu really drew its rows, not just an empty shell of itself.
      expect(sideMenuRow('Holdings'), findsOneWidget);
    });

    testWidgets('a large tablet gets the side menu too', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _largeTablet);

      expect(find.byType(SideMenu), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(sideMenuRow('Holdings'), findsOneWidget);
    });

    testWidgets('the side menu carries the brand mark', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);

      expect(
        find.descendant(
          of: find.byType(SideMenu),
          matching: find.byType(BrandHeader),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a phone shows no brand mark — there is no menu to head', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _phone);

      expect(find.byType(BrandHeader), findsNothing);
    });

    // Wide enough for the menu, too short for six labels without scrolling.
    testWidgets('a phone on its side can still reach the last menu entry', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, 844, height: 390);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(screen(AppSection.settings), findsOneWidget);
    });
  });

  group('moving between sections', () {
    testWidgets('a bottom tab opens its screen', (WidgetTester tester) async {
      await pumpFrame(tester, _phone);
      expect(screen(AppSection.console), findsOneWidget);

      await tester.tap(find.text('Holdings'));
      await tester.pumpAndSettle();

      expect(screen(AppSection.holdings), findsOneWidget);
      expect(screen(AppSection.console), findsNothing);
    });

    testWidgets('a side menu entry opens its screen', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      expect(screen(AppSection.orders), findsOneWidget);
    });

    testWidgets('a screen reader can open a side menu entry', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpFrame(tester, _smallTablet);

      // The regression: hiding the row's children hid its tap action as well.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Orders')),
        isSemantics(label: 'Orders', isButton: true, hasTapAction: true),
      );

      tester.semantics.tap(find.semantics.byLabel('Orders'));
      await tester.pumpAndSettle();

      expect(screen(AppSection.orders), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a screen reader can reach the header on a phone', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpFrame(tester, _phone);

      // The page's route once hid everything drawn before it, header included.
      expect(
        find.bySemanticsLabel('Welcome back, Alex Romero'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Account menu')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the header title follows the open screen', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);

      await tester.tap(find.text('Education'));
      await tester.pumpAndSettle();

      // Shows twice — once in the side menu, once in the page header.
      expect(find.text('Education'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.text('Education'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the console greets the user instead of saying Console', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);

      expect(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.text('Welcome back, Alex Romero'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no app bar on either layout', (WidgetTester tester) async {
      await pumpFrame(tester, _phone);
      expect(find.byType(AppBar), findsNothing);

      await pumpFrame(tester, _smallTablet);
      expect(find.byType(AppBar), findsNothing);
    });
  });

  group('the extras on a phone', () {
    testWidgets('are not on the bottom bar', (WidgetTester tester) async {
      await pumpFrame(tester, _phone);

      expect(find.text('Settings'), findsNothing);
      expect(find.text('Tax & Fiscal'), findsNothing);
    });

    testWidgets('are in the profile menu', (WidgetTester tester) async {
      await pumpFrame(tester, _phone);
      await openProfileMenu(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Tax & Fiscal'), findsOneWidget);
    });

    testWidgets('open like a sub-page: no bar, and a way back', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _phone);
      await openProfileMenu(tester);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(screen(AppSection.settings), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(screen(AppSection.console), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('go back to Console on the system back button too', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _phone);
      await openProfileMenu(tester);
      await tester.tap(find.text('Tax & Fiscal'));
      await tester.pumpAndSettle();

      // Simulates the Android back button.
      final bool handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(screen(AppSection.console), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('leave the menu once the side menu lists them', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);
      await openProfileMenu(tester);

      // Only the side menu's copy — the profile menu adds none here.
      expect(find.text('Settings'), findsOneWidget);
    });

    for (final AppSection section in AppSection.extras) {
      testWidgets('back dismisses the profile menu on ${section.name} first', (
        WidgetTester tester,
      ) async {
        await pumpFrame(tester, _phone);
        router.go(section.route);
        await tester.pumpAndSettle();
        await openProfileMenu(tester);
        expect(find.text('Sign out'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Sign out'), findsNothing);
        expect(screen(section), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(screen(AppSection.console), findsOneWidget);
      });

      for (final bool rootDialog in <bool>[true, false]) {
        testWidgets(
          'back dismisses a ${rootDialog ? 'root' : 'branch'} dialog on ${section.name} first',
          (WidgetTester tester) async {
            await pumpFrame(tester, _phone);
            router.go(section.route);
            await tester.pumpAndSettle();
            unawaited(
              showDialog<void>(
                context: tester.element(screen(section)),
                useRootNavigator: rootDialog,
                builder: (BuildContext context) =>
                    const AlertDialog(title: Text('Test dialog')),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);

            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();

            expect(find.byType(AlertDialog), findsNothing);
            expect(screen(section), findsOneWidget);

            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(screen(AppSection.console), findsOneWidget);
          },
        );
      }
    }
  });

  group('the profile menu', () {
    testWidgets('shows the initials of the signed-in user', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _phone);

      expect(find.text('AR'), findsOneWidget);
    });

    // The popup has a fixed width, so a long label at 2x text used to overflow.
    testWidgets('still fits when the reader has enlarged the text', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _phone, textScale: 2);
      await openProfileMenu(tester);

      expect(
        MediaQuery.textScalerOf(
          tester.element(find.text('Tax & Fiscal')),
        ).scale(14),
        28,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Tax & Fiscal'), findsOneWidget);
    });

    testWidgets('signs the user out', (WidgetTester tester) async {
      await pumpFrame(tester, _phone);
      await openProfileMenu(tester);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(authCubit.signedOut, isTrue);
    });

    testWidgets('opens clear of the avatar on a phone', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _phone);
      final double avatarBottom = tester
          .getBottomLeft(find.byType(CircleAvatar))
          .dy;

      await openProfileMenu(tester);

      // Covering the avatar and the bell beside it was the original bug.
      expect(
        tester.getTopLeft(find.text('Sign out')).dy,
        greaterThanOrEqualTo(avatarBottom),
      );
    });

    testWidgets('stays on screen from the foot of the side menu', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);
      await openProfileMenu(tester);

      // The avatar sits at the bottom, so the menu has to rise to fit.
      expect(
        tester.getBottomLeft(find.text('Sign out')).dy,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
    });

    testWidgets('sits in the page header on a phone', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _phone);

      final Finder inHeader = find.descendant(
        of: find.byType(PageHeader),
        matching: find.byType(CircleAvatar),
      );
      expect(inHeader, findsOneWidget);
      // Only one avatar anywhere — never shown in two places at once.
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('sits at the bottom of the side menu on a tablet', (
      WidgetTester tester,
    ) async {
      await pumpFrame(tester, _smallTablet);

      final Finder inHeader = find.descendant(
        of: find.byType(PageHeader),
        matching: find.byType(CircleAvatar),
      );
      expect(inHeader, findsNothing);
      expect(
        find.descendant(
          of: find.byType(SideMenu),
          matching: find.byType(CircleAvatar),
        ),
        findsOneWidget,
      );
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    for (final Size size in <Size>[
      const Size(800, 900),
      const Size(844, 390),
    ]) {
      testWidgets('keeps the profile inside device insets at $size', (
        WidgetTester tester,
      ) async {
        const EdgeInsets insets = EdgeInsets.only(left: 44, bottom: 34);
        await pumpFrame(
          tester,
          size.width,
          height: size.height,
          insets: insets,
        );

        final Rect avatar = tester.getRect(find.byType(CircleAvatar));
        expect(avatar.left, greaterThanOrEqualTo(insets.left));
        expect(avatar.bottom, lessThanOrEqualTo(size.height - insets.bottom));
        expect(tester.takeException(), isNull);

        await openProfileMenu(tester);
        await tester.tap(find.text('Sign out'));
        await tester.pumpAndSettle();
        expect(authCubit.signedOut, isTrue);
      });
    }
  });
}
