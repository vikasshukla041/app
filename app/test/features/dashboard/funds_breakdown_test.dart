import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/core/design_system/tokens/app_typography.dart';
import 'package:activotrade_app/features/dashboard/widgets/funds_breakdown.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const String _cash = '€24,320.00';
const String _unsettled = '€1,850.00';
const String _collateral = '€116,680.00';

// Not device widths: the test font is much wider, so only the rule is asserted.
const List<double> _widths = <double>[300, 390, 500, 768, 1000, 1200];

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    double textScale = 1,
    ThemeData? theme,
  }) async {
    // The default 800px viewport would clamp the wider cases without a word.
    tester.view.physicalSize = Size(width, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? ActivoTradeTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              // A scroll view hands its child unbounded height, which once threw.
              child: SingleChildScrollView(
                child: SizedBox(
                  width: width,
                  child: const FundsBreakdown(
                    availableCash: _cash,
                    unsettled: _unsettled,
                    collateral: _collateral,
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

  // Finding a Text proves nothing: an ellipsised amount is still found in full.
  void expectWholeAmounts(WidgetTester tester, String where) {
    for (final String amount in <String>[_cash, _unsettled, _collateral]) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.text(amount),
      );
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '$amount is cut off at $where',
      );
    }
  }

  List<Offset> amountPositions(WidgetTester tester) {
    return <Offset>[
      tester.getTopLeft(find.text(_cash)),
      tester.getTopLeft(find.text(_unsettled)),
      tester.getTopLeft(find.text(_collateral)),
    ];
  }

  group('amounts stay whole', () {
    for (final double width in _widths) {
      testWidgets('at ${width.toInt()}px', (WidgetTester tester) async {
        await pumpAt(tester, width);

        expect(tester.takeException(), isNull);
        expectWholeAmounts(tester, '${width.toInt()}px');
      });
    }
  });

  group('amounts stay whole with the text enlarged', () {
    for (final double width in <double>[390, 768, 1200]) {
      testWidgets('at ${width.toInt()}px', (WidgetTester tester) async {
        await pumpAt(tester, width, textScale: 1.3);

        expect(tester.takeException(), isNull);
        expectWholeAmounts(tester, '${width.toInt()}px and 1.3x text');
      });
    }
  });

  testWidgets('stacks the cards when the column is narrow', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, _widths.first);

    final List<Offset> positions = amountPositions(tester);
    expect(positions[1].dy, greaterThan(positions[0].dy));
    expect(positions[2].dy, greaterThan(positions[1].dy));
  });

  testWidgets('sets the cards abreast when the column is wide', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, _widths.last);

    final List<Offset> positions = amountPositions(tester);
    expect(positions[1].dx, greaterThan(positions[0].dx));
    expect(positions[2].dx, greaterThan(positions[1].dx));
    expect(positions[1].dy, positions[0].dy);
  });

  testWidgets('stacks that same wide column once the text is enlarged', (
    WidgetTester tester,
  ) async {
    await pumpAt(tester, _widths.last, textScale: 3);

    final List<Offset> positions = amountPositions(tester);
    expect(positions[1].dy, greaterThan(positions[0].dy));
  });

  testWidgets('reflows when the theme changes figure size and card margins', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = ActivoTradeTheme.darkTheme;
    final AppFigureText figures = theme.extension<AppFigureText>()!;
    final ThemeData updated = theme.copyWith(
      cardTheme: theme.cardTheme.copyWith(
        margin: const EdgeInsets.symmetric(horizontal: 24),
      ),
      extensions: <ThemeExtension<dynamic>>[
        theme.extension<AppSemanticColors>()!,
        theme.extension<AppCategoryColors>()!,
        figures.copyWith(
          medium: figures.medium.copyWith(fontSize: 32, letterSpacing: 2),
        ),
      ],
    );

    await pumpAt(tester, 1200, theme: theme);
    final List<Offset> before = amountPositions(tester);
    expect(before[1].dy, before[0].dy);

    await pumpAt(tester, 1200, theme: updated);
    final List<Offset> stacked = amountPositions(tester);
    expect(stacked[1].dy, greaterThan(stacked[0].dy));
    expect(tester.takeException(), isNull);
    expectWholeAmounts(tester, '1200px with larger figures and margins');

    await pumpAt(tester, 1600, theme: updated);
    final List<Offset> wide = amountPositions(tester);
    expect(wide[1].dy, wide[0].dy);
    expect(wide[1].dx, greaterThan(wide[0].dx));
    expect(tester.takeException(), isNull);
    expectWholeAmounts(tester, '1600px with larger figures and margins');
  });
}
