import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/core/design_system/widgets/app_badge.dart';
import 'package:activotrade_app/core/design_system/widgets/app_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Narrower than the label needs, which is the whole point of the test.
const double _narrow = 110;

void main() {
  Future<void> pumpBadge(
    WidgetTester tester,
    String label, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ActivoTradeTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Center(
                child: SizedBox(
                  width: _narrow,
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: AppBadge(label: label, tone: AppTone.brand),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wraps a long label rather than overflowing the pill', (
    WidgetTester tester,
  ) async {
    await pumpBadge(tester, 'Aggregated across every account');

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppBadge)).width, lessThan(_narrow + 1));
  });

  testWidgets('still fits when the reader has enlarged the text', (
    WidgetTester tester,
  ) async {
    await pumpBadge(tester, 'Aggregated', textScale: 2);

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppBadge)).width, lessThan(_narrow + 1));
  });
}
