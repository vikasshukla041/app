import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/core/design_system/tokens/app_sizing.dart';
import 'package:activotrade_app/features/dashboard/widgets/net_worth_card.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _total = '€142,850.20';

/// A 390 phone once the screen's own padding is taken off either side.
const double _phoneColumn = 350;

void main() {
  Future<void> pumpCard(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ActivoTradeTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const SingleChildScrollView(
                child: SizedBox(
                  width: _phoneColumn,
                  child: NetWorthCard(
                    totalValue: _total,
                    chart: SizedBox(height: AppSizing.chartHeight),
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

  // Painted bounds, because text that spills past its card raises nothing at all.
  void expectInsideCard(WidgetTester tester, String text) {
    final Rect painted = tester.getRect(find.text(text));
    final Rect card = tester.getRect(find.byType(Card));

    expect(painted.left, greaterThanOrEqualTo(card.left));
    expect(painted.right, lessThanOrEqualTo(card.right));
  }

  for (final double scale in <double>[1, 1.3, 1.6, 2]) {
    testWidgets('holds the whole total on a phone at ${scale}x text', (
      WidgetTester tester,
    ) async {
      await pumpCard(tester, textScale: scale);

      expect(tester.takeException(), isNull);
      expectInsideCard(tester, _total);
    });
  }

  // The badge sat beside the label unbounded, so enlarged text pushed it off the card.
  testWidgets('keeps the aggregated badge inside the card', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, textScale: 1.6);

    expect(tester.takeException(), isNull);
    expectInsideCard(tester, 'Aggregated');
  });
}
