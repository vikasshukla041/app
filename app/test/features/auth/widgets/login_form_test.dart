import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:activotrade_app/features/auth/auth_state.dart';
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
      ),
    ).thenAnswer((_) async {});
  });

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
    expect(fields.every((TextField field) => !(field.enabled ?? true)), isTrue);
  });

  testWidgets('calls login with trimmed username', (WidgetTester tester) async {
    await pumpForm(tester, const AuthInitial());

    await tester.enterText(find.byType(TextField).first, ' demo ');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => cubit.login(username: 'demo', password: 'password123'),
    ).called(1);
  });

  testWidgets('preserves password whitespace', (WidgetTester tester) async {
    await pumpForm(tester, const AuthInitial());

    await tester.enterText(find.byType(TextField).first, 'demo');
    await tester.enterText(find.byType(TextField).last, ' pass word ');
    await tester.tap(find.byType(ElevatedButton));

    verify(
      () => cubit.login(username: 'demo', password: ' pass word '),
    ).called(1);
  });

  testWidgets('offers no biometric entry point', (WidgetTester tester) async {
    await pumpForm(tester, const AuthInitial());

    // Unlocking a saved session belongs to LockedScreen, so the credentials
    // form must never expose one.
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
