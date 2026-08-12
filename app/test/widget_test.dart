import 'package:activotrade_app/core/di/service_locator.dart';
import 'package:activotrade_app/features/auth/widgets/login_form.dart';
import 'package:activotrade_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Real flutter_secure_storage has no test-mode implementation, so an unmocked
// call on this channel never replies and checkSession() hangs forever on
// AppAuthInitial — the splash's indeterminate spinner then keeps scheduling
// frames and pumpAndSettle() never settles. Mocking the channel gives
// checkSession() a fast, defined "nothing stored" answer.
const MethodChannel _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  setUp(() async {
    // ensureInitialized() hands back the binding, so the messenger is reached
    // through it rather than a static getter.
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();

    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _secureStorageChannel,
      (MethodCall call) async => null,
    );

    // Registrations are singletons, so a second setupServiceLocator() would
    // throw. Awaited, not fire-and-forget: reset() disposes singletons
    // asynchronously, and a discarded future would let the next test call
    // setupServiceLocator() before the old registrations are gone.
    await getIt.reset();
  });

  testWidgets('app boots to the login screen', (WidgetTester tester) async {
    setupServiceLocator();
    await tester.pumpWidget(const ActivoTradeApp());

    // checkSession() has not answered yet, so the first frame must be the
    // splash — never the login form, which would flash and be replaced.
    expect(find.byType(LoginForm), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Localization delegates load asynchronously; the first frame renders
    // before AppLocalizations is ready.
    await tester.pumpAndSettle();

    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
