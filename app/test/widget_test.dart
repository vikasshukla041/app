import 'package:activotrade_app/features/auth/widgets/login_form.dart';
import 'package:activotrade_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ActivoTradeApp());
    // Localization delegates load asynchronously; the first frame renders
    // before AppLocalizations is ready.
    await tester.pumpAndSettle();

    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
