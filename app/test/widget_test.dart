import 'package:activotrade_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ActivoTradeApp());

    expect(find.text('ActivoTrade'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
