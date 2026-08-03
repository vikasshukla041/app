import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:activotrade_app/features/auth/auth_state.dart';
import 'package:activotrade_app/features/auth/widgets/biometric_opt_in_tile.dart';
import 'package:activotrade_app/features/auth/widgets/biometrics_button.dart';
import 'package:activotrade_app/features/auth/widgets/login_form.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit cubit;

  setUp(() {
    cubit = MockAuthCubit();
    when(
      () => cubit.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        enableBiometrics: any(named: 'enableBiometrics'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => cubit.loginWithBiometrics(reason: any(named: 'reason')),
    ).thenAnswer((_) async {});
  });

  // Pumps the form with the localization delegates the widgets require,
  // and a mock cubit so no network, storage or platform call is made.
  Future<void> pumpForm(WidgetTester tester, AuthState state) async {
    when(() => cubit.state).thenReturn(state);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AuthCubit>.value(
            value: cubit,
            child: const LoginForm(),
          ),
        ),
      ),
    );
    // A single pump is enough: the generated localization delegate resolves
    // via a SynchronousFuture. pumpAndSettle would hang here instead — the
    // AuthLoading case renders an indeterminate CircularProgressIndicator,
    // which animates forever and never "settles".
    await tester.pump();
  }

  testWidgets('shows the sign-in label and enabled fields when idle', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester, const AuthInitial());

    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final Iterable<TextField> fields = tester.widgetList<TextField>(
      find.byType(TextField),
    );
    expect(fields.every((TextField field) => field.enabled ?? true), isTrue);
  });

  testWidgets('disables inputs and shows a spinner while loading', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester, const AuthLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Log In'), findsNothing);

    final Iterable<TextField> fields = tester.widgetList<TextField>(
      find.byType(TextField),
    );
    expect(fields.every((TextField field) => field.enabled ?? true), isFalse);

    final ElevatedButton button = tester.widget<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('forwards a trimmed username and untouched password', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester, const AuthInitial());

    await tester.enterText(find.byType(TextField).first, '  demo  ');
    await tester.enterText(find.byType(TextField).last, ' pass word ');
    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => cubit.login(
        username: 'demo',
        password: ' pass word ',
      ),
    ).called(1);
  });

  group('biometrics', () {
    testWidgets('renders the button disabled when there is nothing to unlock', (
      WidgetTester tester,
    ) async {
      await pumpForm(tester, const AuthInitial());

      expect(find.byType(BiometricOptInTile), findsNothing);
      expect(find.byType(BiometricsButton), findsOneWidget);

      final OutlinedButton button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('offers the opt-in when no session is saved yet', (
      WidgetTester tester,
    ) async {
      await pumpForm(
        tester,
        const AuthInitial(canOfferBiometricSetup: true),
      );

      expect(find.byType(BiometricOptInTile), findsOneWidget);

      final OutlinedButton button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('passes the opt-in through to the cubit when ticked', (
      WidgetTester tester,
    ) async {
      await pumpForm(
        tester,
        const AuthInitial(canOfferBiometricSetup: true),
      );

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));

      verify(
        () => cubit.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
          enableBiometrics: true,
        ),
      ).called(1);
    });

    testWidgets('offers unlock when a saved session exists', (
      WidgetTester tester,
    ) async {
      await pumpForm(
        tester,
        const AuthInitial(canLoginWithBiometrics: true),
      );

      expect(find.byType(BiometricsButton), findsOneWidget);
      expect(find.byType(BiometricOptInTile), findsNothing);

      await tester.tap(find.byType(OutlinedButton));

      verify(
        () => cubit.loginWithBiometrics(reason: any(named: 'reason')),
      ).called(1);
    });
  });
}
